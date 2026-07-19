#!/usr/bin/env bash
# Release check orchestration.
#
# Runs every mandatory V1 gate, records each run's real outcome under
# generated/evidence/, and only then runs identity_tools, which generates the
# release reports from that evidence. A suite that was not run, or that failed,
# leaves evidence saying so and fails the release check -- the reports can no
# longer claim a suite was satisfied when it never executed.

set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

EVIDENCE="$ROOT/generated/evidence"
mkdir -p "$EVIDENCE"

FAILED=0

# record <name> <status> <detail>
record() {
  printf 'status:%s\ndetail:%s\n' "$2" "$3" > "$EVIDENCE/$1.txt"
  printf 'release-check:%s:%s:%s\n' "$1" "$2" "$3"
  [ "$2" = passed ] || FAILED=1
}

run_crate() {
  # run_crate <evidence-name> <crate-dir> <executable>
  local name="$1" dir="$2" exe="$3" out rc
  if ! out=$(cd "$dir" && alr build 2>&1); then
    record "$name" failed "build failed"
    printf '%s\n' "$out" | tail -20
    return
  fi
  out=$(cd "$dir" && "./bin/$exe" 2>&1)
  rc=$?
  if [ "$rc" -eq 0 ]; then
    record "$name" passed "exit 0"
  else
    record "$name" failed "exit $rc"
    printf '%s\n' "$out" | tail -20
  fi
}

echo "== library =="
if ! out=$(alr build 2>&1); then
  echo "$out" | tail -20
  echo "release-check:library:failed"
  exit 1
fi

echo "== aunit suite =="
run_crate aunit "$ROOT/crates/identity_tests" identity_tests

echo "== repository conformance =="
run_crate conformance "$ROOT/crates/identity_conformance" identity_conformance

echo "== examples =="
run_crate examples "$ROOT/crates/identity_examples" identity_lifecycle

echo "== gnatprove =="
# The proof gate is satisfied only when GNATprove reports zero unproved checks
# for the units in registries/proof-scope.json.
if ! command -v gnatprove >/dev/null 2>&1; then
  record gnatprove failed "gnatprove not installed"
else
  prove_out=$(gnatprove -P identity.gpr -aP "$ROOT/../cryptolib" \
                --mode=all --level=2 -j0 2>&1)
  # Findings and SPARK legality errors are counted separately: a unit that is
  # rejected as not-in-SPARK produces NO findings, so counting findings alone
  # would score an unanalysed unit as clean.
  unproved=$(printf '%s\n' "$prove_out" \
             | grep -E ' (medium|high|low): ' | grep -vc '^cryptolib-')
  legality=$(printf '%s\n' "$prove_out" \
             | grep -E '^[a-z0-9_.-]+\.ad[bs]:[0-9]+:[0-9]+: error:' \
             | grep -vc '^cryptolib-')
  # Every non-excluded package in proof-scope.json must actually be analysed.
  summary="$(ls -1 obj/*/gnatprove/gnatprove.out 2>/dev/null | head -1)"
  missing_units=0
  while read -r unit; do
    [ -n "$unit" ] || continue
    if ! grep -qi -- "$unit" "${summary:-/dev/null}" 2>/dev/null; then
      missing_units=$((missing_units + 1))
      echo "release-check:proof:not-analysed:$unit"
    fi
  done <<< "$(python3 - <<'PY'
import json
d = json.load(open('registries/proof-scope.json'))
for p in d['packages']:
    if not p.get('excluded'):
        print(p['name'])
PY
)"
  if [ "$unproved" -eq 0 ] && [ "$legality" -eq 0 ] && [ "$missing_units" -eq 0 ]; then
    total=$(grep -E '^Total' "${summary:-/dev/null}" 2>/dev/null | head -1 | awk '{print $2}')
    record gnatprove passed "checks ${total:-unknown} unproved 0"
  else
    record gnatprove failed \
      "unproved $unproved legality-errors $legality not-analysed $missing_units"
    printf '%s\n' "$prove_out" \
      | grep -E ' (medium|high|low): |: error: ' | grep -v '^cryptolib-' | head -20
  fi
fi

echo "== gate self-tests =="
if [ -x "$ROOT/tools/gate-selftests.sh" ]; then
  if selftest_out=$("$ROOT/tools/gate-selftests.sh" "$ROOT" 2>&1); then
    record gate-selftests passed \
      "$(printf '%s\n' "$selftest_out" | grep -o 'gate-selftest:total:.*' | tail -1)"
  else
    record gate-selftests failed "one or more gate self-tests failed"
    printf '%s\n' "$selftest_out" | grep 'gate-selftest:FAIL' | head -20
  fi
else
  record gate-selftests failed "tools/gate-selftests.sh missing or not executable"
fi

echo "== identity_tools gates =="
if ! out=$(cd "$ROOT/crates/identity_tools" && alr build 2>&1); then
  printf '%s\n' "$out" | tail -20
  echo "release-check:identity_tools:failed:build"
  exit 1
fi
if "$ROOT/crates/identity_tools/bin/identity_tools"; then
  echo "release-check:identity_tools:passed"
else
  echo "release-check:identity_tools:failed"
  FAILED=1
fi

if [ "$FAILED" -eq 0 ]; then
  echo "release-check:result:passed"
  exit 0
fi
echo "release-check:result:failed"
exit 1
