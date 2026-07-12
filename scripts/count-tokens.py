#!/usr/bin/env python3
"""Count exact Anthropic tokens for ADD plugin auto-loaded content.

Compares main branch (before) vs current branch (after).
Uses anthropic-tokenizer for local, offline token counting.

The auto-loaded set is derived from rule frontmatter: every rule in
core/rules/*.md carries an explicit `autoload: true|false` key; only
`autoload: true` rules count as auto-loaded. Knowledge and reference
files are ON-DEMAND (loaded by skills), never auto-loaded.
"""

import re
import subprocess
from pathlib import Path

from anthropic_tokenizer import count_tokens

REPO_ROOT = Path(__file__).resolve().parent.parent
CORE_RULES = REPO_ROOT / "core" / "rules"
PLUGIN = REPO_ROOT / "plugins" / "add"


def git_show(ref: str, path: str) -> str:
    try:
        r = subprocess.run(["git", "show", f"{ref}:{path}"],
                           capture_output=True, text=True, check=True,
                           cwd=REPO_ROOT)
        return r.stdout
    except subprocess.CalledProcessError:
        return ""


def read_file(path: str) -> str:
    try:
        with open(REPO_ROOT / path) as f:
            return f.read()
    except FileNotFoundError:
        return ""


def frontmatter_autoload(path: Path) -> bool:
    """Parse the YAML frontmatter `autoload:` key. Only `true` is autoloaded."""
    text = path.read_text()
    m = re.match(r"\A---\n(.*?)\n---", text, re.DOTALL)
    if not m:
        return False
    am = re.search(r"^autoload:\s*(\S+)", m.group(1), re.MULTILINE)
    return bool(am) and am.group(1).strip().lower() == "true"


# Derive autoloaded rules from core/rules frontmatter; count the compiled
# plugin output (plugins/add/rules/) since that is what ships and loads.
autoload_rules = []
ondemand_rules = []
for rule in sorted(CORE_RULES.glob("*.md")):
    compiled = f"plugins/add/rules/{rule.name}"
    if frontmatter_autoload(rule):
        autoload_rules.append(compiled)
    else:
        ondemand_rules.append(compiled)

# Knowledge files are ON-DEMAND (curated best practices read by skills)
knowledge = sorted(
    str(p.relative_to(REPO_ROOT)) for p in (PLUGIN / "knowledge").glob("*.md")
)
# Reference rules are ON-DEMAND (loaded via skill `references:` frontmatter)
references = sorted(
    str(p.relative_to(REPO_ROOT)) for p in (PLUGIN / "references").glob("*.md")
)

all_auto = autoload_rules

# --- BEFORE ---
before = {}
for f in all_auto:
    c = git_show("main", f)
    before[f] = count_tokens(c) if c else 0

# --- AFTER ---
after = {}
for f in all_auto:
    c = read_file(f)
    after[f] = count_tokens(c) if c else 0

# --- ON-DEMAND (knowledge + references + non-autoload rules) ---
ondemand_sections = [
    ("KNOWLEDGE (on-demand, read by skills)", knowledge),
    ("REFERENCES (on-demand, not auto-loaded)", references),
    ("ON-DEMAND RULES (autoload: false)", ondemand_rules),
]
ondemand = {}
for _, files in ondemand_sections:
    for f in files:
        c = read_file(f)
        ondemand[f] = count_tokens(c) if c else 0

before_total = sum(before.values())
after_total = sum(after.values())
ondemand_total = sum(ondemand.values())
saved = before_total - after_total
pct = round((1 - after_total / before_total) * 100) if before_total else 0

print()
print("=" * 72)
print("  ADD Plugin Token Optimization — EXACT TOKEN COUNT")
print("  (measured via anthropic-tokenizer, same tokenizer as Claude API)")
print("=" * 72)
print()
print(f"  AUTO-LOADED CONTEXT (every session — {len(all_auto)} rules,")
print("  derived from `autoload: true` frontmatter in core/rules/)")
print("  " + "─" * 46)
print(f"  {'Before (main):':<25} {before_total:>10,} tokens")
print(f"  {'After (optimized):':<25} {after_total:>10,} tokens")
print(f"  {'Saved:':<25} {saved:>10,} tokens  (-{pct}%)")
print()
print("  ON-DEMAND CONTENT (loaded by skills, not auto-loaded)")
print("  " + "─" * 46)
print(f"  {'Total:':<25} {ondemand_total:>10,} tokens")
print()

print("  PER-FILE BREAKDOWN (auto-loaded)")
print("  " + "─" * 66)
print(f"  {'File':<40} {'Before':>8} {'After':>8} {'Change':>8}")
print(f"  {'─' * 40} {'─' * 8} {'─' * 8} {'─' * 8}")

for f in all_auto:
    name = f.split("/")[-1]
    b, a = before[f], after[f]
    diff = a - b
    if diff != 0:
        print(f"  {name:<40} {b:>8,} {a:>8,} {diff:>+8,}")
    else:
        print(f"  {name:<40} {b:>8,} {a:>8,}        —")

for title, files in ondemand_sections:
    print()
    print(f"  {title}")
    print(f"  {'─' * 40}          {'─' * 8}")
    for f in files:
        name = f.split("/")[-1]
        print(f"  {name:<40}          {ondemand[f]:>8,}")

print()
print("  COST IMPACT (~{:,} tokens saved per session)".format(saved))
print("  " + "─" * 56)
print(f"  {'':40} {'Opus $15/M':>12} {'Sonnet $3/M':>12}")
opus = saved * 15 / 1_000_000
sonnet = saved * 3 / 1_000_000
print(f"  {'Per session':<40} {'$' + f'{opus:.4f}':>12} {'$' + f'{sonnet:.4f}':>12}")
print(f"  {'Per 100 sessions':<40} {'$' + f'{opus * 100:.2f}':>12} {'$' + f'{sonnet * 100:.2f}':>12}")
print(f"  {'Per 1,000 sessions':<40} {'$' + f'{opus * 1000:.2f}':>12} {'$' + f'{sonnet * 1000:.2f}':>12}")
print()
print("=" * 72)
