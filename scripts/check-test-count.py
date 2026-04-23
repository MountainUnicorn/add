#!/usr/bin/env python3
"""check-test-count.py — Test Deletion Guardrail for ADD.

Implements the comparison + gate portion of specs/test-deletion-guardrail.md.

Three modes:

    snapshot   — discover test functions in the working tree and write a snapshot JSON
                 (--phase red|green; writes to .add/cycles/cycle-{N}/tdd-{slug}-{phase}.json)
    compare    — compare two snapshots and print a ComparisonResult as JSON
    gate       — run compare + apply pass/fail rules (exit 1 if tests removed without
                 override). Invoked by /add:verify Gate 3.5.

The minimal one-shot form used by /add:verify's Gate 3.5 and by CI dog-food checks:

    python3 scripts/check-test-count.py --baseline <ref>

This is shorthand for: take a snapshot of the working tree NOW, a snapshot of the tree at
<ref>, compare them, and fail if the net test count dropped with no justification marker
in the commit trailer range <ref>..HEAD or in a `.add/cycles/*/overrides.json` file.

Justification markers accepted:

    1. Commit trailer in the range <ref>..HEAD:     [ADD-TEST-DELETE: <reason>]
    2. Per-cycle override file:                     .add/cycles/*/overrides.json
                                                    kind == "test-rewrite"

Covers spec ACs: 008, 009, 010, 011, 014, 015, 016, 017, 028-enforcement.

No external dependencies — stdlib only (pyyaml optional for config parsing).
"""

from __future__ import annotations

import argparse
import datetime as dt
import fnmatch
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CATALOG = ROOT / "core" / "knowledge" / "test-discovery-patterns.json"
# For consumer projects (where the plugin is installed), fall back to plugins/add copy
FALLBACK_CATALOG = ROOT / "plugins" / "add" / "knowledge" / "test-discovery-patterns.json"

COMMIT_TRAILER_RE = re.compile(r"\[ADD-TEST-DELETE:\s*([^\]]+?)\s*\]")

# -----------------------------------------------------------------------------
# Catalog loading
# -----------------------------------------------------------------------------


def load_catalog(path: Path | None = None) -> dict:
    p = path or DEFAULT_CATALOG
    if not p.exists():
        p = FALLBACK_CATALOG
    if not p.exists():
        raise FileNotFoundError(
            f"test-discovery-patterns.json not found at {DEFAULT_CATALOG} or {FALLBACK_CATALOG}"
        )
    return json.loads(p.read_text())


# -----------------------------------------------------------------------------
# Body normalization + hashing
# -----------------------------------------------------------------------------

_WS_RE = re.compile(r"\s+")
_PY_COMMENT_RE = re.compile(r"#[^\n]*")
_C_LINE_COMMENT_RE = re.compile(r"//[^\n]*")
_C_BLOCK_COMMENT_RE = re.compile(r"/\*.*?\*/", re.DOTALL)


def normalize_body(body: str, fn_name: str) -> str:
    """Strip whitespace, comments, and the function name itself.

    Implements AC-012 — a rename with identical body should produce the same hash.
    """
    text = body
    text = _PY_COMMENT_RE.sub("", text)
    text = _C_BLOCK_COMMENT_RE.sub("", text)
    text = _C_LINE_COMMENT_RE.sub("", text)
    # Strip the function name token itself (word-boundary replacement)
    if fn_name:
        text = re.sub(rf"\b{re.escape(fn_name)}\b", "_FN_", text)
    text = _WS_RE.sub(" ", text).strip()
    return text


def body_hash(body: str, fn_name: str) -> str:
    return hashlib.sha1(normalize_body(body, fn_name).encode("utf-8")).hexdigest()


# -----------------------------------------------------------------------------
# Test discovery
# -----------------------------------------------------------------------------


def file_matches_any(path: str, globs: list[str]) -> bool:
    for g in globs:
        if fnmatch.fnmatch(path, g) or fnmatch.fnmatch(Path(path).name, g):
            return True
    # Also match any path where a component fits the glob's tail
    for g in globs:
        if "**" in g:
            tail = g.split("**/")[-1]
            if fnmatch.fnmatch(Path(path).name, tail):
                return True
    return False


def detect_language_for_file(path: str, catalog: dict) -> str | None:
    for lang, spec in catalog.get("languages", {}).items():
        if file_matches_any(path, spec.get("file_globs", [])):
            return lang
    return None


def discover_tests_in_file(path: Path, lang: str, catalog: dict) -> list[dict]:
    """Return a list of TestFunction dicts for this file."""
    spec = catalog["languages"][lang]
    try:
        text = path.read_text(errors="replace")
    except Exception:
        return []

    funcs: list[dict] = []
    seen_pos: set[tuple[int, str]] = set()

    for pat_cfg in spec.get("patterns", []):
        if pat_cfg.get("is_group"):
            # describe() blocks are organizational, not leaf tests
            continue
        regex = re.compile(pat_cfg["regex"], re.MULTILINE)
        grp = pat_cfg.get("function_name_group", 1)
        for m in regex.finditer(text):
            name = m.group(grp)
            line_start = text[: m.start()].count("\n") + 1
            key = (line_start, name)
            if key in seen_pos:
                continue
            seen_pos.add(key)
            body = _extract_body(text, m.end(), spec.get("body_terminator", "balanced_braces"))
            funcs.append(
                {
                    "name": name,
                    "body_hash": body_hash(body, name),
                    "line_start": line_start,
                }
            )
    return funcs


def _extract_body(text: str, start: int, terminator: str) -> str:
    """Extract a function body from position `start` using a naive terminator strategy."""
    if terminator == "balanced_braces":
        # Find the opening brace after start, then track depth
        brace = text.find("{", start)
        if brace == -1:
            # No braces — grab until next blank line
            nl = text.find("\n\n", start)
            return text[start : nl if nl != -1 else min(start + 2000, len(text))]
        depth = 0
        i = brace
        while i < len(text):
            ch = text[i]
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    return text[brace : i + 1]
            i += 1
        return text[brace:]
    elif terminator == "dedent_to_def_level":
        # Python: indentation-based. Capture lines more indented than the def line.
        lines = text[start:].splitlines(keepends=True)
        body_lines: list[str] = []
        base_indent = None
        for line in lines:
            if not line.strip():
                body_lines.append(line)
                continue
            indent = len(line) - len(line.lstrip(" \t"))
            if base_indent is None:
                base_indent = indent
                body_lines.append(line)
            elif indent >= base_indent:
                body_lines.append(line)
            else:
                break
        return "".join(body_lines)
    elif terminator == "end_keyword":
        # Ruby: match until matching `end`
        depth = 1
        i = start
        while i < len(text):
            m = re.search(r"\b(def|do|class|module|if|case|begin|end)\b", text[i:])
            if not m:
                break
            kw = m.group(1)
            i += m.end()
            if kw == "end":
                depth -= 1
                if depth == 0:
                    return text[start:i]
            elif kw in {"def", "do", "class", "module", "if", "case", "begin"}:
                depth += 1
        return text[start : min(start + 2000, len(text))]
    return text[start : min(start + 2000, len(text))]


def discover_all_tests(
    cwd: Path,
    catalog: dict,
    file_filter: callable | None = None,
) -> tuple[list[dict], int]:
    """Walk `cwd` and discover all test functions across known languages.

    Returns (files_list, total_functions). files_list is a list of TestFile dicts.
    """
    files_out: list[dict] = []
    total = 0

    # Walk the tree, skipping heavy dirs
    skip_dirs = {".git", "node_modules", "__pycache__", ".venv", "venv", "dist", "build", "target"}
    for dirpath, dirnames, filenames in os.walk(cwd):
        dirnames[:] = [d for d in dirnames if d not in skip_dirs]
        for fname in filenames:
            rel = str(Path(dirpath, fname).relative_to(cwd))
            lang = detect_language_for_file(rel, catalog)
            if not lang:
                continue
            if file_filter and not file_filter(rel):
                continue
            funcs = discover_tests_in_file(Path(dirpath) / fname, lang, catalog)
            if not funcs:
                continue
            files_out.append(
                {
                    "path": rel,
                    "language": lang,
                    "function_count": len(funcs),
                    "functions": funcs,
                }
            )
            total += len(funcs)

    files_out.sort(key=lambda f: f["path"])
    return files_out, total


# -----------------------------------------------------------------------------
# Git helpers
# -----------------------------------------------------------------------------


def git(*args: str, cwd: Path | None = None) -> str:
    try:
        out = subprocess.run(
            ["git", *args],
            cwd=str(cwd) if cwd else None,
            check=True,
            capture_output=True,
            text=True,
        )
        return out.stdout.strip()
    except subprocess.CalledProcessError as e:
        return ""


def git_show_tree(ref: str, cwd: Path, dest: Path) -> Path:
    """Materialize the tree at `ref` into `dest` using git archive (no checkout)."""
    dest.mkdir(parents=True, exist_ok=True)
    # Use git archive to avoid modifying HEAD
    try:
        archive = subprocess.run(
            ["git", "archive", "--format=tar", ref],
            cwd=str(cwd),
            check=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError as e:
        raise SystemExit(f"git archive {ref} failed: {e.stderr.decode(errors='replace')}")

    import tarfile
    import io

    tf = tarfile.open(fileobj=io.BytesIO(archive.stdout))
    tf.extractall(dest)
    return dest


def commit_trailers_in_range(base: str, head: str = "HEAD", cwd: Path | None = None) -> list[str]:
    """Return list of [ADD-TEST-DELETE: ...] reasons found in commits base..head."""
    log = git("log", "--format=%B%x00", f"{base}..{head}", cwd=cwd)
    if not log:
        return []
    reasons = []
    for body in log.split("\x00"):
        for m in COMMIT_TRAILER_RE.finditer(body):
            reasons.append(m.group(1).strip())
    return reasons


# -----------------------------------------------------------------------------
# Comparison
# -----------------------------------------------------------------------------


def _functions_by_key(files: list[dict]) -> dict[str, dict]:
    """key = path::name -> {path, name, body_hash, line_start}"""
    out = {}
    for f in files:
        for fn in f["functions"]:
            key = f"{f['path']}::{fn['name']}"
            out[key] = {
                "path": f["path"],
                "name": fn["name"],
                "body_hash": fn["body_hash"],
                "line_start": fn.get("line_start"),
            }
    return out


def compare_snapshots(red: dict, green: dict) -> dict:
    """Produce a ComparisonResult JSON per AC-008."""
    red_funcs = _functions_by_key(red.get("files", []))
    green_funcs = _functions_by_key(green.get("files", []))

    # Same key (path::name) on both sides
    same_keys = set(red_funcs) & set(green_funcs)
    # Removed: in red, not in green by key AND body-hash not found anywhere in green
    red_only_keys = set(red_funcs) - same_keys
    green_only_keys = set(green_funcs) - same_keys

    green_hashes = {fn["body_hash"]: key for key, fn in green_funcs.items()}
    red_hashes = {fn["body_hash"]: key for key, fn in red_funcs.items()}

    renamed: list[dict] = []
    truly_removed_keys: set[str] = set()
    for key in red_only_keys:
        fn = red_funcs[key]
        if fn["body_hash"] in green_hashes:
            renamed.append(
                {
                    "from": key,
                    "to": green_hashes[fn["body_hash"]],
                    "body_hash": fn["body_hash"],
                }
            )
        else:
            truly_removed_keys.add(key)

    truly_added_keys: set[str] = set()
    for key in green_only_keys:
        fn = green_funcs[key]
        if fn["body_hash"] not in red_hashes:
            truly_added_keys.add(key)
        # else it was a rename destination — already counted

    # Replacements: same key, different body hash
    replaced: list[dict] = []
    for key in same_keys:
        if red_funcs[key]["body_hash"] != green_funcs[key]["body_hash"]:
            replaced.append(
                {
                    "path": red_funcs[key]["path"],
                    "name": red_funcs[key]["name"],
                    "red_hash": red_funcs[key]["body_hash"],
                    "green_hash": green_funcs[key]["body_hash"],
                }
            )

    removed_details = []
    for key in sorted(truly_removed_keys):
        fn = red_funcs[key]
        removed_details.append(
            {
                "path": fn["path"],
                "name": fn["name"],
                "red_body_hash": fn["body_hash"],
                "line_start": fn.get("line_start"),
            }
        )

    return {
        "tests_added": len(truly_added_keys),
        "tests_removed": len(truly_removed_keys),
        "tests_renamed": len(renamed),
        "tests_replaced": replaced,
        "removed_details": removed_details,
        "renamed_details": renamed,
        "added_details": sorted(truly_added_keys),
    }


# -----------------------------------------------------------------------------
# Overrides lookup
# -----------------------------------------------------------------------------


def find_overrides(project_root: Path) -> list[dict]:
    """Scan .add/cycles/**/overrides.json for test-rewrite overrides."""
    overrides_dir = project_root / ".add" / "cycles"
    if not overrides_dir.exists():
        return []
    out = []
    for f in overrides_dir.rglob("overrides.json"):
        try:
            data = json.loads(f.read_text())
        except Exception:
            continue
        # Support both object-shape and list-of-objects shape
        records = data if isinstance(data, list) else [data]
        for rec in records:
            if isinstance(rec, dict) and rec.get("kind") == "test-rewrite":
                out.append(rec)
    return out


# -----------------------------------------------------------------------------
# Snapshot builders
# -----------------------------------------------------------------------------


def build_snapshot(
    cycle_id: int,
    spec_slug: str,
    phase: str,
    cwd: Path,
    catalog: dict,
    base_sha: str | None = None,
) -> dict:
    files, total = discover_all_tests(cwd, catalog)
    languages = sorted({f["language"] for f in files})
    return {
        "cycle_id": cycle_id,
        "spec_slug": spec_slug,
        "phase": phase,
        "base_sha": base_sha or "",
        "phase_end_sha": git("rev-parse", "HEAD", cwd=cwd) or "",
        "language": "+".join(languages) if languages else "unknown",
        "files": files,
        "total_functions": total,
        "timestamp": dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }


# -----------------------------------------------------------------------------
# Gate logic
# -----------------------------------------------------------------------------


def apply_gate(
    comparison: dict,
    overrides: list[dict],
    commit_trailer_reasons: list[str],
    allow_test_rewrite: bool,
) -> tuple[bool, list[str]]:
    """Return (passed, reasons)."""
    reasons = []
    fail = False

    removed = comparison.get("tests_removed", 0)
    replaced = comparison.get("tests_replaced", [])

    if removed > 0:
        # Build set of removed test identifiers
        removed_ids = {
            f"{d['path']}::{d['name']}" for d in comparison.get("removed_details", [])
        }
        # Overrides collected that explicitly list affected tests
        covered_ids: set[str] = set()
        for ov in overrides:
            for aff in ov.get("affected_tests", []):
                covered_ids.add(aff)

        uncovered = removed_ids - covered_ids
        # Commit trailer is a blanket cover if at least one exists — but we still list the
        # removed tests for audit. (Spec Q5: consider surfacing in /add:retro.)
        if uncovered and not commit_trailer_reasons:
            fail = True
            reasons.append(
                f"tests_removed={removed} without override — {len(uncovered)} test(s) "
                f"lack a justification marker"
            )
            for rid in sorted(uncovered):
                reasons.append(f"  removed: {rid}")
            reasons.append(
                "  Remediation: (a) reinstate the removed test(s), (b) add a "
                "commit trailer `[ADD-TEST-DELETE: <reason>]` in the range, or "
                "(c) rerun with --allow-test-rewrite and record an override in "
                ".add/cycles/cycle-{N}/overrides.json"
            )

    if replaced and not allow_test_rewrite:
        # Replacements: same name, body hash differs. Any replacement without override fails.
        covered_names: set[str] = set()
        for ov in overrides:
            for aff in ov.get("affected_tests", []):
                covered_names.add(aff)
        uncovered_rep = [
            r for r in replaced
            if f"{r['path']}::{r['name']}" not in covered_names
        ]
        if uncovered_rep:
            fail = True
            reasons.append(
                f"tests_replaced={len(uncovered_rep)} without --allow-test-rewrite + "
                "recorded approval — same-name body rewrite is a TDD-cycle violation"
            )
            for r in uncovered_rep:
                reasons.append(f"  replaced: {r['path']}::{r['name']}")

    return (not fail, reasons)


# -----------------------------------------------------------------------------
# CLI
# -----------------------------------------------------------------------------


def cmd_snapshot(args: argparse.Namespace) -> int:
    catalog = load_catalog(Path(args.catalog) if args.catalog else None)
    cwd = Path(args.cwd).resolve() if args.cwd else Path.cwd()
    snapshot = build_snapshot(
        cycle_id=args.cycle_id,
        spec_slug=args.spec_slug,
        phase=args.phase,
        cwd=cwd,
        catalog=catalog,
        base_sha=args.base_sha,
    )
    out_path = Path(args.out) if args.out else (
        cwd / ".add" / "cycles" / f"cycle-{args.cycle_id}" / f"tdd-{args.spec_slug}-{args.phase}.json"
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(snapshot, indent=2) + "\n")

    # AC-006: fail if RED snapshot has zero tests added vs a zero baseline
    if args.phase == "red" and args.fail_on_empty:
        if snapshot["total_functions"] == 0:
            print(
                "ERROR: RED phase produced no failing tests — TDD violation.",
                file=sys.stderr,
            )
            return 1

    print(json.dumps({"snapshot": str(out_path), "total_functions": snapshot["total_functions"]}))
    return 0


def cmd_compare(args: argparse.Namespace) -> int:
    red = json.loads(Path(args.red).read_text())
    green = json.loads(Path(args.green).read_text())
    result = compare_snapshots(red, green)
    if args.format == "summary":
        print(_format_summary(result))
    else:
        print(json.dumps(result, indent=2))
    return 0


def _format_summary(r: dict) -> str:
    return (
        f"tests_added: {r['tests_added']}, "
        f"tests_removed: {r['tests_removed']}, "
        f"tests_renamed: {r['tests_renamed']}, "
        f"tests_replaced: {len(r['tests_replaced'])}"
    )


def cmd_gate(args: argparse.Namespace) -> int:
    """Gate 3.5 — Test Surface Integrity."""
    project_root = Path(args.project_root).resolve() if args.project_root else Path.cwd()

    red_path = Path(args.red) if args.red else None
    green_path = Path(args.green) if args.green else None

    if not red_path or not red_path.exists():
        print(
            "ERROR: RED snapshot not found. "
            "Provide --red or run snapshot at end of RED phase.",
            file=sys.stderr,
        )
        return 1
    if not green_path or not green_path.exists():
        # AC-015 exact language
        print(
            "ERROR: GREEN snapshot not found — cycle is incomplete or "
            "test-writer/implementer skipped snapshotting.",
            file=sys.stderr,
        )
        return 1

    try:
        red = json.loads(red_path.read_text())
        green = json.loads(green_path.read_text())
    except json.JSONDecodeError as e:
        print(f"ERROR: snapshot parse error: {e}", file=sys.stderr)
        return 1

    comparison = compare_snapshots(red, green)
    overrides = find_overrides(project_root)
    trailers = []
    baseline = getattr(args, "gate_baseline", None) or args.baseline
    if baseline:
        trailers = commit_trailers_in_range(baseline, "HEAD", cwd=project_root)

    allow_rewrite = getattr(args, "gate_allow_rewrite", False) or args.allow_test_rewrite
    passed, reasons = apply_gate(
        comparison, overrides, trailers, allow_test_rewrite=allow_rewrite
    )

    # Always emit a structured summary (AC-017)
    summary = {
        "gate": "3.5 — Test Surface Integrity",
        "status": "PASS" if passed else "FAIL",
        **comparison,
        "override_used": bool(overrides) or bool(trailers),
        "override_count": len(overrides) + len(trailers),
    }
    print(json.dumps(summary, indent=2))

    if not passed:
        print("", file=sys.stderr)
        print("Gate 3.5 FAILED — Test Surface Integrity violation:", file=sys.stderr)
        for r in reasons:
            print(f"  {r}", file=sys.stderr)
        print("", file=sys.stderr)
        print(
            "  Directive: Test deletion during a TDD cycle is forbidden. "
            "Fix the implementation, not the test.",
            file=sys.stderr,
        )
        return 1
    return 0


def cmd_baseline(args: argparse.Namespace) -> int:
    """Shorthand: snapshot current tree + snapshot baseline tree + gate.

    Implements the one-shot entry point `--baseline <ref>` used by /add:verify
    Gate 3.5 and by dog-food / CI checks.
    """
    catalog = load_catalog(Path(args.catalog) if args.catalog else None)
    cwd = Path.cwd()

    # Snapshot current tree
    current = build_snapshot(
        cycle_id=0,
        spec_slug="baseline-current",
        phase="green",
        cwd=cwd,
        catalog=catalog,
    )

    # Materialize baseline tree into a temp dir
    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        try:
            git_show_tree(args.baseline, cwd, Path(tmp))
        except SystemExit as e:
            print(f"ERROR: {e}", file=sys.stderr)
            return 2
        baseline = build_snapshot(
            cycle_id=0,
            spec_slug="baseline-prior",
            phase="red",
            cwd=Path(tmp),
            catalog=catalog,
        )
        baseline["base_sha"] = args.baseline

    comparison = compare_snapshots(baseline, current)
    trailers = commit_trailers_in_range(args.baseline, "HEAD", cwd=cwd)
    overrides = find_overrides(cwd)

    passed, reasons = apply_gate(
        comparison, overrides, trailers, allow_test_rewrite=args.allow_test_rewrite
    )

    summary = {
        "baseline": args.baseline,
        "status": "PASS" if passed else "FAIL",
        "baseline_test_count": baseline["total_functions"],
        "current_test_count": current["total_functions"],
        **comparison,
        "trailer_overrides": trailers,
        "file_overrides": len(overrides),
    }
    print(json.dumps(summary, indent=2))

    if not passed:
        print("", file=sys.stderr)
        print("Test-deletion guardrail FAILED:", file=sys.stderr)
        for r in reasons:
            print(f"  {r}", file=sys.stderr)
        return 1
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="check-test-count.py",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--baseline",
        help="Git ref — shorthand for snapshot-current + snapshot-ref + gate. "
        "This is the primary entry point invoked by /add:verify Gate 3.5.",
    )
    parser.add_argument("--allow-test-rewrite", action="store_true")
    parser.add_argument("--catalog", help="Path to test-discovery-patterns.json (for testing)")

    sub = parser.add_subparsers(dest="cmd")

    p_snap = sub.add_parser("snapshot", help="Write a RED or GREEN snapshot")
    p_snap.add_argument("--phase", choices=["red", "green"], required=True)
    p_snap.add_argument("--cycle-id", type=int, required=True)
    p_snap.add_argument("--spec-slug", required=True)
    p_snap.add_argument("--cwd", help="Root directory to scan (default cwd)")
    p_snap.add_argument("--base-sha", help="Git SHA at cycle start")
    p_snap.add_argument("--out", help="Output path (default .add/cycles/cycle-{N}/...)")
    p_snap.add_argument("--catalog", help="Path to test-discovery-patterns.json")
    p_snap.add_argument(
        "--fail-on-empty",
        action="store_true",
        help="AC-006: fail if RED snapshot has zero tests",
    )

    p_cmp = sub.add_parser("compare", help="Compare RED and GREEN snapshots")
    p_cmp.add_argument("--red", required=True)
    p_cmp.add_argument("--green", required=True)
    p_cmp.add_argument("--format", choices=["json", "summary"], default="json")

    p_gate = sub.add_parser("gate", help="Apply Gate 3.5 rules")
    p_gate.add_argument("--red", required=True)
    p_gate.add_argument("--green", required=True)
    p_gate.add_argument("--project-root", help="Project root (for overrides lookup)")
    p_gate.add_argument("--baseline", dest="gate_baseline", help="Optional base ref for commit-trailer scan")
    p_gate.add_argument("--allow-test-rewrite", dest="gate_allow_rewrite", action="store_true")

    args = parser.parse_args(argv)

    # One-shot --baseline form
    if args.baseline and not args.cmd:
        return cmd_baseline(args)

    if args.cmd == "snapshot":
        return cmd_snapshot(args)
    if args.cmd == "compare":
        return cmd_compare(args)
    if args.cmd == "gate":
        return cmd_gate(args)

    parser.print_help()
    return 2


if __name__ == "__main__":
    sys.exit(main())
