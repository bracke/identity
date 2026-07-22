#!/usr/bin/env bash
# Code-coverage gate.
#
# Measures a real, executed line-coverage number for the identity library and
# fails the release when it drops below a threshold. There is no self-reported
# "I believe this is covered" here: the AUnit suite is compiled with GCC
# coverage instrumentation (-fprofile-arcs -ftest-coverage), run once, and the
# resulting .gcda execution data is reduced by gcov to a measured percentage.
#
# The gate is scored on BODY coverage (.adb under src/public + src/adapters):
# the executable statements of the library. Package specs (.ads) are reported
# for transparency but not gated -- their "executable" lines are expression
# functions and predicates that GNATprove verifies statically, so gcov counting
# them as unexecuted runtime code is an artifact, not a coverage hole.
#
# The instrumented object files are removed and the test crate rebuilt clean at
# the end, so this step leaves the tree in a normal (non-instrumented) state.

set -u

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$ROOT" || exit 1

# Minimum accepted body coverage. A ratchet set just under the current measured
# figure: it catches a regression without failing on noise. Raise it as the
# suite grows; never lower it silently.
MIN_BODY="${COVERAGE_MIN_BODY:-80.0}"

TESTS_DIR="$ROOT/crates/identity_tests"
REPORT="$ROOT/generated/release/coverage.txt"
mkdir -p "$ROOT/generated/release"

echo "coverage: cleaning prior instrumentation data"
find "$ROOT/obj" -name '*.gcda' -delete 2>/dev/null
find "$ROOT/obj" -name '*.gcno' -delete 2>/dev/null

echo "coverage: building AUnit suite with GCC coverage instrumentation"
# -f forces full recompilation. Without it gprbuild sees unchanged switches and
# skips units, leaving no freshly-generated .gcno for gcov to reduce -- yielding
# a false 0% regardless of what actually ran.
if ! build_out=$(cd "$TESTS_DIR" && \
      alr build -- -f -cargs -fprofile-arcs -ftest-coverage \
                   -largs -fprofile-arcs 2>&1); then
  echo "release-check:coverage:failed:instrumented-build"
  printf '%s\n' "$build_out" | tail -20
  exit 1
fi

echo "coverage: running instrumented suite"
if ! run_out=$("$TESTS_DIR/bin/identity_tests" 2>&1); then
  echo "release-check:coverage:failed:suite-nonzero-exit"
  printf '%s\n' "$run_out" | tail -20
  exit 1
fi
if ! printf '%s\n' "$run_out" | grep -q 'Failed Assertions: 0'; then
  echo "release-check:coverage:failed:suite-assertions"
  printf '%s\n' "$run_out" | tail -20
  exit 1
fi

echo "coverage: reducing gcov data"
# Aggregate executed/total lines per file, split by body vs spec, restricted to
# the library's own source under src/public and src/adapters.
measure_out=$(cd "$ROOT/obj/development" && python3 - "$REPORT" <<'PY'
import subprocess, glob, re, sys
report_path = sys.argv[1]
gcda = glob.glob("*.gcda")
agg = {".adb": [0, 0], ".ads": [0, 0]}
rows = []
for g in gcda:
    stem = g[:-5]
    if not stem.startswith("identity"):
        continue
    r = subprocess.run(["gcov", "-n", "-b", stem + ".gcda"],
                       capture_output=True, text=True)
    for path, pct, m in re.findall(
            r"File '([^']+)'\nLines executed:([\d.]+)% of (\d+)", r.stdout):
        if "/src/public/" not in path and "/src/adapters/" not in path:
            continue
        ext = ".adb" if path.endswith(".adb") else ".ads"
        m = int(m)
        c = round(float(pct) / 100.0 * m)
        agg[ext][0] += c
        agg[ext][1] += m
        rows.append((float(pct), path.split("/src/")[-1]))

def pct(pair):
    c, t = pair
    return (100.0 * c / t) if t else 0.0

body = pct(agg[".adb"])
spec = pct(agg[".ads"])
tot_c = agg[".adb"][0] + agg[".ads"][0]
tot_t = agg[".adb"][1] + agg[".ads"][1]
comb = (100.0 * tot_c / tot_t) if tot_t else 0.0

with open(report_path, "w") as f:
    f.write("identity library code coverage (measured via gcc/gcov)\n")
    f.write("scope: src/public + src/adapters\n\n")
    f.write(f"body (.adb)  {agg['.adb'][0]}/{agg['.adb'][1]} = {body:.1f}%  [gated]\n")
    f.write(f"spec (.ads)  {agg['.ads'][0]}/{agg['.ads'][1]} = {spec:.1f}%  [reported, GNATprove-verified]\n")
    f.write(f"combined     {tot_c}/{tot_t} = {comb:.1f}%\n\n")
    f.write("lowest-covered body files:\n")
    bodies = sorted(set((p, n) for p, n in rows if n.endswith(".adb")))
    for p, n in bodies[:15]:
        f.write(f"  {p:5.1f}%  {n}\n")

# machine-readable line consumed by the shell gate
print(f"BODY={body:.1f}")
PY
)
rc=$?

echo "coverage: restoring non-instrumented build"
find "$ROOT/obj" -name '*.gcda' -delete 2>/dev/null
find "$ROOT/obj" -name '*.gcno' -delete 2>/dev/null
find "$ROOT/obj" -name '*.gcov' -delete 2>/dev/null
(cd "$TESTS_DIR" && alr build >/dev/null 2>&1)

if [ "$rc" -ne 0 ] || [ -z "$measure_out" ]; then
  echo "release-check:coverage:failed:gcov-reduction"
  exit 1
fi

body_pct=$(printf '%s\n' "$measure_out" | sed -n 's/^BODY=//p' | tail -1)
if [ -z "$body_pct" ]; then
  echo "release-check:coverage:failed:no-measurement"
  exit 1
fi

# Compare as fixed-point to avoid a float-dependent shell.
below=$(awk -v got="$body_pct" -v min="$MIN_BODY" 'BEGIN{print (got+0 < min+0) ? 1 : 0}')
if [ "$below" -eq 1 ]; then
  echo "release-check:coverage:failed:body-${body_pct}%-below-min-${MIN_BODY}%"
  exit 1
fi

echo "release-check:coverage:passed:body-${body_pct}%-min-${MIN_BODY}%"
exit 0
