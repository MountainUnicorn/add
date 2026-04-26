#!/usr/bin/env python3
"""Count exact Anthropic tokens for ADD plugin auto-loaded content.

Compares main branch (before) vs current branch (after).
Uses anthropic-tokenizer for local, offline token counting.
"""

import subprocess
from anthropic_tokenizer import count_tokens


def git_show(ref: str, path: str) -> str:
    try:
        r = subprocess.run(["git", "show", f"{ref}:{path}"],
                           capture_output=True, text=True, check=True)
        return r.stdout
    except subprocess.CalledProcessError:
        return ""


def read_file(path: str) -> str:
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        return ""


rules = [
    "plugins/add/rules/learning.md",
    "plugins/add/rules/agent-coordination.md",
    "plugins/add/rules/human-collaboration.md",
    "plugins/add/rules/quality-gates.md",
    "plugins/add/rules/design-system.md",
    "plugins/add/rules/maturity-lifecycle.md",
    "plugins/add/rules/project-structure.md",
    "plugins/add/rules/environment-awareness.md",
    "plugins/add/rules/version-migration.md",
    "plugins/add/rules/add-compliance.md",
    "plugins/add/rules/source-control.md",
    "plugins/add/rules/tdd-enforcement.md",
    "plugins/add/rules/spec-driven.md",
    "plugins/add/rules/maturity-loader.md",
    "plugins/add/rules/registry-sync.md",
]
knowledge = [
    "plugins/add/knowledge/global.md",
    "plugins/add/knowledge/image-gen-detection.md",
]
references = [
    "plugins/add/references/design-system.md",
    "plugins/add/references/image-gen-detection.md",
    "plugins/add/references/learning-reference.md",
    "plugins/add/references/swarm-protocol.md",
    "plugins/add/references/quality-checks-matrix.md",
]

all_auto = rules + knowledge

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

# --- REFERENCES ---
refs = {}
for f in references:
    c = read_file(f)
    refs[f] = count_tokens(c) if c else 0

before_total = sum(before.values())
after_total = sum(after.values())
ref_total = sum(refs.values())
saved = before_total - after_total
pct = round((1 - after_total / before_total) * 100)

print()
print("=" * 72)
print("  ADD Plugin Token Optimization — EXACT TOKEN COUNT")
print("  (measured via anthropic-tokenizer, same tokenizer as Claude API)")
print("=" * 72)
print()
print("  AUTO-LOADED CONTEXT (every session)")
print("  " + "─" * 46)
print(f"  {'Before (main):':<25} {before_total:>10,} tokens")
print(f"  {'After (optimized):':<25} {after_total:>10,} tokens")
print(f"  {'Saved:':<25} {saved:>10,} tokens  (-{pct}%)")
print()
print("  ON-DEMAND REFERENCES (loaded by skills)")
print("  " + "─" * 46)
print(f"  {'Total:':<25} {ref_total:>10,} tokens")
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

print()
print("  REFERENCES (on-demand, not auto-loaded)")
print(f"  {'─' * 40}          {'─' * 8}")
for f in references:
    name = f.split("/")[-1]
    print(f"  {name:<40}          {refs[f]:>8,}")

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
