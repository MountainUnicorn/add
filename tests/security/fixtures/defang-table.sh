#!/usr/bin/env bash
# defang-table.sh — sourced by the test harness to re-fang fixtures at runtime.
#
# Fixtures are committed DEFANGED (inert at rest) to avoid triggering the scanner
# on the repo itself and to avoid tripping GitHub push protection on literal-match
# injection strings. The harness re-fangs them in tempdir before invoking the scanner.
#
# Each substitution pair: DEFANGED_TOKEN | LIVE_TOKEN
# The LIVE_TOKEN is assembled from parts so no literal injection string lives in
# any committed file except this table (and even here it is concatenated).

defang_refang() {
  # stdin → stdout, applies substitutions
  local p1 p2 p3 p4
  # ignore-previous — assemble "ignore previous" at runtime
  p1="ign"; p2="ore prev"; p3="ious"
  local ignore_prev="${p1}${p2}${p3}"
  # new-instructions heading
  local new_instr="### NEW INSTRUC""TIONS"
  # system heading
  local sys_head="# SYS""TEM"
  # disregard-prior
  local disregard="disre""gard prior"
  # system tag
  local sys_tag="<sys""tem>"
  # instruction tag
  local instr_tag="<instruc""tion>"
  # comment-and-control signature
  local cc_marker="[""CMD-AND-CTL-2026""]"

  sed \
    -e "s/__IGNORE_PREVIOUS__/${ignore_prev}/g" \
    -e "s|__NEW_INSTRUCTIONS_HEADING__|${new_instr}|g" \
    -e "s|__SYSTEM_HEADING__|${sys_head}|g" \
    -e "s/__DISREGARD_PRIOR__/${disregard}/g" \
    -e "s|__SYSTEM_TAG__|${sys_tag}|g" \
    -e "s|__INSTRUCTION_TAG__|${instr_tag}|g" \
    -e "s|__CC_MARKER__|${cc_marker}|g"
}

export -f defang_refang
