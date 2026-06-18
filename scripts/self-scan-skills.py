#!/usr/bin/env python3
"""Self-scan: run ADD's own injection-defense patterns against ADD's own
shipped artifacts, so the methodology eats its own dog food.

ADD ships skills/rules/templates/knowledge that a runtime auto-loads as
behavioral instructions. If any of those artifacts themselves trip the
prompt-injection patterns ADD distributes (core/security/patterns.json), that's
either a real problem or a pattern that's too broad — exactly the failure mode
the v0.9.6 unicode-tag-block fix addressed. This scanner is the standing guard:
it's a CI gate AND a publishable trust signal ("0 of N shipped artifacts trip
ADD's own critical/high injection patterns").

Mirrors the detection path in runtimes/claude/hooks/posttooluse-scan.sh:
byte-mode regex (unicode_escape -> latin1) for patterns containing \\x escapes,
Python re otherwise. Honors a (?i) prefix as IGNORECASE.

Exit 0 = clean (no unexpected matches). Exit 1 = a shipped artifact tripped a
pattern outside the allowlist.

Usage:
    python3 scripts/self-scan-skills.py            # scan + gate
    python3 scripts/self-scan-skills.py --json      # machine-readable summary
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CORE = ROOT / "core"
PATTERNS = CORE / "security" / "patterns.json"

# Artifact trees that ship to users and are read as instructions / content.
SCAN_DIRS = ["skills", "rules", "templates", "knowledge", "references", "lib"]

# Per-(file, pattern) waivers for files that legitimately QUOTE injection
# examples while documenting the defense. Scoped to the exact patterns each file
# is expected to trip — NOT whole-file exemptions — so an UNEXPECTED injection
# planted in one of these still trips the gate. Only files that actually trip a
# pattern need an entry; files that trip nothing must not be allowlisted (that
# only manufactures blind spots). The patterns.json catalog itself is excluded
# structurally (it's not a behavioral artifact). Populated from a verified
# no-allowlist scan; see test/CI for the audit.
WAIVERS: dict[str, set[str]] = {
    # threat-model.md quotes a <system> tag, an instruction tag, and a
    # "## New instructions" heading while documenting the attacks.
    "knowledge/threat-model.md": {"system-tag", "instruction-tag", "new-instructions-heading"},
    # injection-defense.md quotes a <system> tag and an instruction tag.
    "rules/injection-defense.md": {"system-tag", "instruction-tag"},
}

# Only gate on the severities that matter; informational matches are reported
# but don't fail CI.
GATING_SEVERITIES = {"critical", "high"}


def prepare_pattern(regex: str):
    """Mirror the hook's two detection paths.

    Returns (kind, payload, ignorecase):
      kind 'bytes' -> compiled byte-mode Python regex (for \\x escape patterns)
      kind 'ere'   -> the ERE string handed to `grep -E` (POSIX semantics,
                      exactly like the hook — avoids Python-re POSIX-class drift)
    """
    flags = re.DOTALL
    body = regex
    ignorecase = False
    # Strip leading inline flags (?i)/(?m) in ANY order, exactly like the hook's
    # normalize_regex(). grep -E rejects an inline (?m) as an invalid regex
    # (rc=2), which would silently disable the pattern — the bug this guards.
    while True:
        if body.startswith("(?i)"):
            ignorecase = True
            body = body[4:]
            continue
        if body.startswith("(?m)"):  # grep is inherently line-based; (?m) is implicit
            body = body[4:]
            continue
        break
    if "\\x" in body:
        pat = body.encode("utf-8").decode("unicode_escape").encode("latin1")
        return ("bytes", re.compile(pat, flags | (re.IGNORECASE if ignorecase else 0)), ignorecase)
    return ("ere", body, ignorecase)


def ere_is_valid(payload: str, ignorecase: bool) -> bool:
    """One-time check that grep -E accepts the pattern (rc<2 against empty input)."""
    cmd = ["grep", "-E", "-q"] + (["-i"] if ignorecase else []) + ["--", payload]
    return subprocess.run(cmd, input=b"", stdout=subprocess.DEVNULL,
                          stderr=subprocess.DEVNULL).returncode < 2


def file_matches(kind, payload, ignorecase, path: Path) -> bool:
    if kind == "bytes":
        return bool(payload.search(path.read_bytes()))
    # ERE via grep -E, identical engine to the runtime hook.
    cmd = ["grep", "-E", "-q"] + (["-i"] if ignorecase else []) + ["--", payload, str(path)]
    rc = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode
    if rc >= 2:
        # invalid regex / read error — surface loudly rather than silently miss
        print(f"WARN: grep error (rc={rc}) applying pattern to {path}", file=sys.stderr)
        return False
    return rc == 0


def main() -> int:
    as_json = "--json" in sys.argv
    # --root <dir> scans an alternate tree (used by the test harness); the
    # pattern catalog is always the real one in core/security/.
    scan_root = CORE
    if "--root" in sys.argv:
        scan_root = Path(sys.argv[sys.argv.index("--root") + 1]).resolve()
    catalog = json.loads(PATTERNS.read_text())
    pats = catalog["patterns"] if isinstance(catalog, dict) else catalog
    compiled = []
    broken = []
    for p in pats:
        try:
            kind, payload, ic = prepare_pattern(p["regex"])
        except re.error as e:
            print(f"WARN: could not compile pattern {p.get('name')}: {e}", file=sys.stderr)
            broken.append(p.get("name"))
            continue
        # One-time validation: a pattern grep rejects would silently never gate.
        if kind == "ere" and not ere_is_valid(payload, ic):
            print(f"WARN: pattern '{p.get('name')}' is an invalid ERE — grep rejects it; "
                  f"it WILL NOT gate. Fix the catalog.", file=sys.stderr)
            broken.append(p.get("name"))
            continue
        compiled.append((p["name"], p.get("severity", "medium"), kind, payload, ic))

    scanned = 0
    findings = []
    for d in SCAN_DIRS:
        base = scan_root / d
        if not base.exists():
            continue
        for f in sorted(base.rglob("*")):
            if not f.is_file():
                continue
            rel = f.relative_to(scan_root).as_posix()
            # The pattern catalog itself is not a behavioral artifact — skip it
            # structurally (it IS the patterns). Everything else is scanned;
            # specific (file, pattern) pairs are waived below, not whole files.
            if rel == "security/patterns.json":
                continue
            if f.suffix not in {".md", ".json", ".yaml", ".yml", ".sh", ".txt"}:
                continue
            scanned += 1
            waived = WAIVERS.get(rel, set())
            for name, sev, kind, payload, ic in compiled:
                if file_matches(kind, payload, ic, f):
                    if name in waived:
                        continue  # expected: this file documents this pattern
                    findings.append({"file": rel, "pattern": name, "severity": sev})

    gating = [x for x in findings if x["severity"] in GATING_SEVERITIES]

    if as_json:
        print(json.dumps({
            "scanned": scanned,
            "patterns": len(compiled),
            "findings": findings,
            "gating_findings": len(gating),
            "clean": len(gating) == 0,
        }, indent=2))
    else:
        print(f"ADD skill self-scan: {scanned} shipped artifacts vs {len(compiled)} injection patterns")
        if not findings:
            print(f"✓ clean — 0 artifacts trip ADD's own injection patterns")
        else:
            for x in findings:
                marker = "FAIL" if x["severity"] in GATING_SEVERITIES else "info"
                print(f"  [{marker}] {x['file']} :: {x['pattern']} ({x['severity']})")
            if gating:
                print(f"✗ {len(gating)} gating ({'/'.join(sorted(GATING_SEVERITIES))}) match(es) in shipped artifacts")
            else:
                print(f"✓ clean of gating severities ({len(findings)} informational match(es) only)")

    return 1 if gating else 0


if __name__ == "__main__":
    sys.exit(main())
