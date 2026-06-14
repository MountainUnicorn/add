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

# Files that legitimately CONTAIN injection examples or detection patterns by
# design — scanning them would be self-referential. Paths are relative to core/.
ALLOWLIST = {
    "security/patterns.json",          # the patterns themselves
    "knowledge/threat-model.md",       # documents attack examples
    "knowledge/secret-patterns.md",    # secret-detection examples
    "rules/injection-defense.md",      # describes the very patterns it defends against
    "rules/secrets-handling.md",       # documents secret patterns
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
    if body.startswith("(?i)"):
        ignorecase = True
        body = body[4:]
    if "\\x" in body:
        pat = body.encode("utf-8").decode("unicode_escape").encode("latin1")
        return ("bytes", re.compile(pat, flags | (re.IGNORECASE if ignorecase else 0)), ignorecase)
    return ("ere", body, ignorecase)


def file_matches(kind, payload, ignorecase, path: Path) -> bool:
    if kind == "bytes":
        return bool(payload.search(path.read_bytes()))
    # ERE via grep -E, identical engine to the runtime hook
    cmd = ["grep", "-E", "-q"]
    if ignorecase:
        cmd.append("-i")
    cmd += ["--", payload, str(path)]
    return subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def main() -> int:
    as_json = "--json" in sys.argv
    catalog = json.loads(PATTERNS.read_text())
    pats = catalog["patterns"] if isinstance(catalog, dict) else catalog
    compiled = []
    for p in pats:
        try:
            kind, payload, ic = prepare_pattern(p["regex"])
            compiled.append((p["name"], p.get("severity", "medium"), kind, payload, ic))
        except re.error as e:
            print(f"WARN: could not compile pattern {p.get('name')}: {e}", file=sys.stderr)

    scanned = 0
    findings = []
    for d in SCAN_DIRS:
        base = CORE / d
        if not base.exists():
            continue
        for f in sorted(base.rglob("*")):
            if not f.is_file():
                continue
            rel = f.relative_to(CORE).as_posix()
            if rel in ALLOWLIST:
                continue
            if f.suffix not in {".md", ".json", ".yaml", ".yml", ".sh", ".txt"}:
                continue
            scanned += 1
            for name, sev, kind, payload, ic in compiled:
                if file_matches(kind, payload, ic, f):
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
