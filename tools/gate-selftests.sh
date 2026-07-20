#!/usr/bin/env bash
#
# gate-selftests.sh -- negative-test harness for the identity_tools release gates.
#
# Every release gate implemented by crates/identity_tools asserts that some piece
# of evidence exists (a registry entry, a fixture file, a workflow gate id, ...).
# Until this harness existed, nothing proved those gates actually FAIL when the
# evidence is removed: a gate that never fires is indistinguishable from a gate
# that always passes.
#
# For each negative case the harness copies the repository into a throwaway
# directory, applies exactly one targeted mutation there, runs the ORIGINAL
# identity_tools executable with that copy as its working directory, and requires
# both a non-zero exit status AND the specific diagnostic marker belonging to the
# mutated gate. Requiring the marker is what keeps the suite honest: the tool
# already exits non-zero for unrelated reasons, so an exit-code-only assertion
# would pass vacuously even if the mutation silently failed to apply. Each
# mutation additionally verifies that it changed something and aborts the case if
# it did not.
#
# Positive cases assert that the tool (and the sibling harnesses referenced by the
# invariant registry) actually report the counts they claim to report.
#
# Each case label is printed verbatim; the labels are the "required_tests" names
# from registries/invariants.json and are matched literally by the traceability
# validator in identity_tools_invariants.adb.
#
# Usage: tools/gate-selftests.sh [repo-root]

set -u

SEP=$'\x1f'

REPO_DEFAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="${1:-$REPO_DEFAULT}"
REPO="$(cd "$REPO" && pwd)"

TOOL="$REPO/crates/identity_tools/bin/identity_tools"
TESTS_BIN="$REPO/crates/identity_tests/bin/identity_tests"
CONFORMANCE_BIN="$REPO/crates/identity_conformance/bin/identity_conformance"
EXAMPLES_BIN="$REPO/crates/identity_examples/bin/identity_lifecycle"
MANIFEST="$REPO/tools/project_tools_workflows.toml"
SUITE_SRC="$REPO/crates/identity_tests/src/identity_tests.adb"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

TOTAL=0
PASSED=0
FAILED=0

###############################################################################
#  Reporting
###############################################################################

record() {
   #  $1 = verbatim case name, $2 = 0 when the case passed
   TOTAL=$((TOTAL + 1))
   if [ "$2" -eq 0 ]; then
      PASSED=$((PASSED + 1))
      printf 'gate-selftest:PASS:%s\n' "$1"
   else
      FAILED=$((FAILED + 1))
      printf 'gate-selftest:FAIL:%s\n' "$1"
   fi
}

note() {
   printf 'gate-selftest:note:%s\n' "$1"
}

###############################################################################
#  Assertion helpers
###############################################################################

#  True when some single line of $1 contains every remaining substring.
has_line() {
   local file="$1"
   shift
   local buffer sub
   [ -f "$file" ] || return 1
   buffer="$(cat "$file")"
   for sub in "$@"; do
      buffer="$(printf '%s\n' "$buffer" | grep -F -- "$sub")" || return 1
      [ -n "$buffer" ] || return 1
   done
   return 0
}

#  Expand a SEP-joined requirement into same-line substrings and check it.
has_requirement() {
   local file="$1" requirement="$2"
   local -a parts=()
   local old_ifs="$IFS"
   IFS="$SEP"
   read -r -d '' -a parts < <(printf '%s\0' "$requirement")
   IFS="$old_ifs"
   has_line "$file" "${parts[@]}"
}

file_has() {
   #  $1 = file, rest = fixed substrings that must each occur somewhere
   local file="$1"
   shift
   local sub
   [ -f "$file" ] || return 1
   for sub in "$@"; do
      grep -qF -- "$sub" "$file" || return 1
   done
   return 0
}

###############################################################################
#  Repository copy / tool invocation
###############################################################################

#  Copy the repository into a fresh temporary directory. Build products and VCS
#  metadata are excluded: identity_tools never reads them (its scanners skip
#  "obj", "alire" and "bin" directories outright) and they dominate the copy
#  cost.
mkcopy() {
   local dir
   dir="$(mktemp -d)" || return 1
   if ! tar -c \
      --exclude=obj \
      --exclude=alire \
      --exclude=.git \
      --exclude=lib \
      --exclude=bin \
      -C "$REPO" . 2>/dev/null | tar -x -C "$dir" 2>/dev/null; then
      rm -rf "$dir"
      return 1
   fi
   printf '%s' "$dir"
}

RC=0
OUT=""

#  Run the original absolute-path executable with $1 as its working directory.
run_tool() {
   OUT="$WORK/tool-out.txt"
   (cd "$1" && "$TOOL") >"$OUT" 2>&1
   RC=$?
}

###############################################################################
#  Mutation primitives
#
#  Each primitive fails (non-zero) when it matched nothing, so a stale pattern
#  aborts its case instead of producing a vacuous pass.
###############################################################################

#  edit_file <file> <mode> <pattern> [replacement]
#  modes: delete-all, delete-first, replace-all, replace-first, set-line-first
edit_file() {
   python3 - "$@" <<'PY'
import sys

path, mode, pattern = sys.argv[1], sys.argv[2], sys.argv[3]
replacement = sys.argv[4] if len(sys.argv) > 4 else None

with open(path, encoding="utf-8") as handle:
    lines = handle.readlines()

out = []
hits = 0
for line in lines:
    if pattern in line and not (hits and mode.endswith("-first")):
        hits += 1
        if mode.startswith("delete"):
            continue
        if mode.startswith("replace"):
            line = line.replace(pattern, replacement)
        elif mode == "set-line-first":
            line = replacement + "\n"
    out.append(line)

if hits == 0:
    sys.stderr.write("gate-selftest: pattern not found: %s in %s\n" % (pattern, path))
    sys.exit(3)

with open(path, "w", encoding="utf-8") as handle:
    handle.writelines(out)
PY
}

append_line() {
   #  $1 = file, $2 = line to append
   [ -f "$1" ] || return 1
   printf '%s\n' "$2" >>"$1" || return 1
}

###############################################################################
#  Case runners
###############################################################################

#  neg_case <name> <mutation-function> <requirement>...
#
#  A requirement is a SEP-joined list of substrings that must all appear on one
#  line of the tool's output.
neg_case() {
   local name="$1" mutate="$2"
   shift 2
   local dir ok=1 requirement
   dir="$(mkcopy)"
   if [ -n "$dir" ] && [ -d "$dir" ]; then
      if "$mutate" "$dir"; then
         run_tool "$dir"
         if [ "$RC" -ne 0 ]; then
            ok=0
            for requirement in "$@"; do
               if ! has_requirement "$OUT" "$requirement"; then
                  note "$name: expected marker absent: ${requirement//$SEP/ + }"
                  ok=1
               fi
            done
         else
            note "$name: tool exited 0 after mutation"
         fi
      else
         note "$name: mutation did not apply"
      fi
      rm -rf "$dir"
   else
      note "$name: repository copy failed"
   fi
   record "$name" "$ok"
}

#  base_line <name> <substring>...
#  Positive case: the substrings must share one line of the baseline output.
base_line() {
   local name="$1"
   shift
   local ok=1
   if has_line "$BASELINE" "$@"; then
      ok=0
   else
      note "$name: baseline line absent: $*"
   fi
   record "$name" "$ok"
}

#  manifest_gate <name> <gate-identifier>
manifest_gate() {
   local name="$1" gate="$2"
   local ok=1
   if file_has "$MANIFEST" "\"$gate\""; then
      ok=0
   else
      note "$name: gate not listed in $MANIFEST: $gate"
   fi
   record "$name" "$ok"
}

###############################################################################
#  Baseline
###############################################################################

if [ ! -x "$TOOL" ]; then
   printf 'gate-selftest:error:missing-executable:%s\n' "$TOOL" >&2
   exit 1
fi

BASELINE="$WORK/baseline.txt"
(cd "$REPO" && "$TOOL") >"$BASELINE" 2>&1
BASELINE_RC=$?
printf 'gate-selftest:baseline-exit:%d\n' "$BASELINE_RC"

###############################################################################
#  Sibling harnesses (evidence owned by the AUnit / conformance / example crates)
###############################################################################

AUNIT_RC=1
if [ -x "$TESTS_BIN" ]; then
   (cd "$REPO" && "$TESTS_BIN") >"$WORK/aunit.txt" 2>&1
   AUNIT_RC=$?
fi

ok=1
if [ "$AUNIT_RC" -eq 0 ] && file_has "$SUITE_SRC" \
   "expanded V1 event constants remain public" \
   "Identity.Events.Types.Session_Created" \
   "Identity.Events.Types.Password_Reset_Requested" \
   "Identity.Events.Types.TOTP_Replay_Detected"; then
   ok=0
fi
record "AUnit verifies expanded public event constants" "$ok"

CONFORMANCE_RC=1
CONFORMANCE_OUT="$WORK/conformance.txt"
: >"$CONFORMANCE_OUT"
if [ -x "$CONFORMANCE_BIN" ]; then
   (cd "$REPO" && "$CONFORMANCE_BIN") >"$CONFORMANCE_OUT" 2>&1
   CONFORMANCE_RC=$?
fi

ok=1
if [ "$CONFORMANCE_RC" -eq 0 ] \
   && file_has "$CONFORMANCE_OUT" "identity_conformance:crypto-core-v1:passed" \
   && ! grep -qF ":failed" "$CONFORMANCE_OUT"; then
   ok=0
fi
record "identity_conformance builds and executable reports all V1 profiles passed" "$ok"

ok=1
if [ "$CONFORMANCE_RC" -eq 0 ] && file_has "$CONFORMANCE_OUT" \
   "identity_conformance:core-identity-store:passed" \
   "identity_conformance:interactive-authentication-store:passed" \
   "identity_conformance:session-store:passed" \
   "identity_conformance:recovery-store:passed" \
   "identity_conformance:federated-identity-store:passed"; then
   ok=0
fi
record "identity_conformance reports all V1 certification profiles" "$ok"

ok=1
if [ -x "$EXAMPLES_BIN" ]; then
   (cd "$REPO" && "$EXAMPLES_BIN") >"$WORK/examples.txt" 2>&1
   if [ $? -eq 0 ] && file_has "$WORK/examples.txt" "identity_lifecycle:ok"; then
      ok=0
   fi
fi
record "identity_examples builds and identity_lifecycle runs" "$ok"

ok=1
if grep -qE '^identity_tools:identity: [0-9]+\. [0-9]+\. [0-9]+:' "$BASELINE"; then
   ok=0
fi
record "identity_tools builds and executable reports version metadata" "$ok"

###############################################################################
#  Negative cases -- architecture and secret-leak scanners
###############################################################################

mutate_architecture() {
   #  A boundary term in a public spec, and a direct cryptolib import in a file
   #  outside the Identity.Crypto.CryptoLib.* isolation subtree. Both words are
   #  assembled at run time so this harness never plants the literals it is
   #  asserting about into a scanned file.
   local dir="$1"
   append_line "$dir/src/public/identity-versions.ads" \
      "--  ro""le assignment placeholder inserted by gate-selftests" || return 1
   append_line "$dir/src/public/identity-events-types.ads" \
      "with Crypto""Lib.Hashes;" || return 1
   return 0
}

neg_case "identity_tools exits nonzero on architecture boundary violations" \
   mutate_architecture \
   "architecture:boundary-term:${SEP}identity-versions.ads" \
   "architecture:crypto-import:${SEP}identity-events-types.ads"

mutate_canary() {
   local dir="$1"
   mkdir -p "$dir/docs" || return 1
   printf '# leak fixture\n\npassword: %s\n' "CAN""ARY-password-123" \
      >"$dir/docs/gate-selftest-canary.md" || return 1
   return 0
}

neg_case "identity_tools exits nonzero on canary secret leaks" \
   mutate_canary \
   "secret-leak:canary:${SEP}gate-selftest-canary.md"

###############################################################################
#  Negative cases -- event registry / public constant coverage
###############################################################################

mutate_drop_registry_event() {
   edit_file "$1/registries/event-types.json" delete-all '"identity.api-key.revoked"'
}

neg_case "identity_tools fails when a public event constant lacks registry coverage" \
   mutate_drop_registry_event \
   "events:missing-registry:identity.api-key.revoked"

mutate_drop_public_event() {
   edit_file "$1/src/public/identity-events-types.ads" delete-all \
      '"identity.api-key.revoked"'
}

neg_case "identity_tools fails when an event registry entry lacks a public constant" \
   mutate_drop_public_event \
   "events:missing-public:identity.api-key.revoked"

###############################################################################
#  Negative cases -- release artifact registry
###############################################################################

mutate_sensitive_artifact() {
   edit_file "$1/registries/release-artifacts.json" replace-first \
      '"contains_sensitive_material": false' \
      '"contains_sensitive_material": true'
}

neg_case "identity_tools fails when artifacts are marked sensitive" \
   mutate_sensitive_artifact \
   "identity_tools:release-validation:${SEP}:sensitive: 1:"

mutate_drop_required_artifact() {
   edit_file "$1/registries/release-artifacts.json" delete-all \
      '"identity.artifact-digests"'
}

neg_case "identity_tools fails when required release artifacts are missing" \
   mutate_drop_required_artifact \
   "release-artifacts:missing-artifact:identity.artifact-digests"

###############################################################################
#  Negative cases -- persisted format registry and fixtures
###############################################################################

mutate_drop_requirement() {
   edit_file "$1/registries/persisted-formats.json" delete-all '"bounded": true'
}

neg_case "identity_tools fails when compatibility requirements are missing" \
   mutate_drop_requirement \
   'persisted-formats:missing-requirement:"bounded": true'

mutate_drop_format() {
   edit_file "$1/registries/persisted-formats.json" delete-all \
      '"identity.event.canonical-envelope"'
}

neg_case "identity_tools fails when persisted format entries are missing" \
   mutate_drop_format \
   "persisted-formats:missing-format:identity.event.canonical-envelope"

mutate_drop_fixture_file() {
   local target="$1/fixtures/persisted-formats/secret-verifier-current.json"
   [ -f "$target" ] || return 1
   rm -f "$target" || return 1
   [ ! -e "$target" ] || return 1
   return 0
}

neg_case "identity_tools fails when persisted fixture files are missing" \
   mutate_drop_fixture_file \
   "persisted-formats:missing-fixture-file:fixtures/persisted-formats/secret-verifier-current.json"

###############################################################################
#  Negative cases -- crypto algorithm registry
###############################################################################

mutate_drop_algorithm() {
   edit_file "$1/registries/crypto-algorithms.json" delete-all \
      '"identity.sha256-domain-verifier"'
}

neg_case "identity_tools fails when mandatory algorithm entries are missing" \
   mutate_drop_algorithm \
   "crypto-algorithms:missing-algorithm:identity.sha256-domain-verifier"

mutate_drop_implementation() {
   edit_file "$1/registries/crypto-algorithms.json" delete-all \
      '"implementation": "cryptolib"'
}

neg_case "identity_tools fails when cryptolib implementation binding is missing" \
   mutate_drop_implementation \
   'crypto-algorithms:missing-field:"implementation": "cryptolib"'

mutate_drop_permissions() {
   #  Removed from every descriptor: the validator only reports a missing field
   #  when no algorithm declares it at all.
   local registry="$1/registries/crypto-algorithms.json"
   edit_file "$registry" delete-all '"creation_allowed": true' || return 1
   edit_file "$registry" delete-all '"verification_allowed": true' || return 1
   return 0
}

neg_case "identity_tools fails when creation and verification permissions are missing" \
   mutate_drop_permissions \
   'crypto-algorithms:missing-field:"creation_allowed": true' \
   'crypto-algorithms:missing-field:"verification_allowed": true'

###############################################################################
#  Negative cases -- invariant registry metadata
###############################################################################

mutate_drop_severity() {
   #  Renaming the key keeps the document valid JSON while removing the field the
   #  gate counts.
   edit_file "$1/registries/invariants.json" replace-first \
      '"failure_severity":' '"failure_severity_withdrawn":'
}

neg_case "identity_tools fails when invariant failure severity is missing" \
   mutate_drop_severity \
   "identity_tools:invariants:${SEP}:severity: 79:"

mutate_empty_required_tests() {
   edit_file "$1/registries/invariants.json" set-line-first \
      '"required_tests": [' '      "required_tests": [],'
}

neg_case "identity_tools fails when invariant required tests are missing" \
   mutate_empty_required_tests \
   "identity_tools:invariants:${SEP}:empty-required-tests: 1:"

###############################################################################
#  Negative cases -- project_tools workflow manifest
###############################################################################

mutate_drop_gate() {
   edit_file "$1/tools/project_tools_workflows.toml" replace-all \
      '"identity-tools-events"' '"identity-tools-events-withdrawn"'
}

neg_case "identity_tools fails when mandatory gate identifiers are missing" \
   mutate_drop_gate \
   "workflows:missing-gate:identity-tools-events"

mutate_drop_workflow() {
   edit_file "$1/tools/project_tools_workflows.toml" replace-all \
      'name = "fixtures-check"' 'name = "fixtures-check-withdrawn"'
}

neg_case "identity_tools fails when required workflow names are missing" \
   mutate_drop_workflow \
   "workflows:missing-workflow:fixtures-check"

mutate_drop_orchestrator() {
   edit_file "$1/tools/project_tools_workflows.toml" delete-all \
      'required = "project_tools"'
}

neg_case "identity_tools fails when project_tools orchestration is missing" \
   mutate_drop_orchestrator \
   "workflows:missing-orchestrator:project_tools"

###############################################################################
#  Negative case -- release reports are gated on validation
###############################################################################

report_case="identity_tools writes release reports only after validation passes"
ok=1
dir="$(mkcopy)"
if [ -n "$dir" ] && [ -d "$dir" ]; then
   rm -rf "$dir/generated/release"
   if edit_file "$dir/registries/release-artifacts.json" delete-all \
      '"identity.release-provenance"'; then
      run_tool "$dir"
      written="$(find "$dir/generated/release" -type f 2>/dev/null | wc -l)"
      if [ "$RC" -eq 0 ]; then
         note "$report_case: tool exited 0 after mutation"
      elif ! has_line "$OUT" "identity_tools:release-reports: 0:write-failures: 0:skipped: 1"; then
         note "$report_case: report generation was not skipped"
      elif [ "$written" -ne 0 ]; then
         note "$report_case: $written report file(s) written despite failing gates"
      else
         ok=0
      fi
   else
      note "$report_case: mutation did not apply"
   fi
   rm -rf "$dir"
else
   note "$report_case: repository copy failed"
fi
record "$report_case" "$ok"

###############################################################################
#  Positive cases -- the tool reports the counts it claims to report
###############################################################################

base_line "identity_tools reports architecture boundary counts" \
   "identity_tools:architecture:" ":internal:" ":crypto-violations:" ":boundary-terms:"

base_line "identity_tools reports canary secret-leak counts" \
   "identity_tools:secret-leaks:" ":canary-hits:"

base_line "identity_tools reports crypto algorithm validation counts" \
   "identity_tools:crypto-validation: 2:classes: 2:" \
   ":missing-algorithms: 0:missing-fields: 0"

# The count is deliberately not pinned: the vocabulary grows as operations are
# audited, and a literal would fail on every addition without indicating a real
# defect. What must hold is that the registry and the public constants agree.
base_line "identity_tools reports event registry coverage counts" \
   "identity_tools:events:" ":missing-public: 0:missing-registry: 0"

ok=1
registry_count=$(grep -c '"identity\.' "$REPO/registries/event-types.json")
public_count=$(grep -c 'constant Identity.Identifiers.Registry.Registry_Id' \
   "$REPO/src/public/identity-events-types.ads")
if [ "$registry_count" -gt 0 ] && [ "$registry_count" -eq "$public_count" ] \
   && has_line "$BASELINE" "identity_tools:events: $registry_count:public: $public_count:" \
      ":missing-public: 0:missing-registry: 0"; then
   ok=0
else
   echo "gate-selftest:note:registry=$registry_count public=$public_count"
fi
record "identity_tools event registry and public constants agree in count" "$ok"

ok=1
if has_line "$BASELINE" "identity_tools:events:" \
   ":missing-public: 0:missing-registry: 0" \
   && file_has "$REPO/registries/event-types.json" \
      "identity.api-key.authenticated" \
      "identity.api-key.revoked" \
      "identity.totp.replay-detected" \
      "identity.external.assertion.replay-detected" \
   && file_has "$REPO/src/public/identity-events-types.ads" \
      "identity.api-key.authenticated" \
      "identity.api-key.revoked" \
      "identity.totp.replay-detected" \
      "identity.external.assertion.replay-detected"; then
   ok=0
fi
record "identity_tools reports expanded V1 event registry coverage" "$ok"

base_line "identity_tools reports invariant registry traceability counts" \
   "identity_tools:invariants:" ":required-tests:" ":test-names:" ":traced:" ":untraced:"

base_line "identity_tools reports persisted format inventory counts" \
   "identity_tools:persisted-formats: 3:fixtures: 12"

base_line "identity_tools reports persisted-format validation counts" \
   "identity_tools:persisted-validation: 3:fixtures: 12:" \
   ":missing-formats: 0:missing-fixtures: 0:missing-requirements: 0:" \
   ":missing-files: 0"

base_line "identity_tools reports proof-scope validation counts" \
   "identity_tools:proof-validation: 10:properties: 10:" \
   ":missing-packages: 0:missing-properties: 0:"

base_line "identity_tools reports release artifact inventory counts" \
   "identity_tools:release-artifacts: 15:prohibited: 8:provenance-fields: 9"

base_line "identity_tools reports release artifact validation counts" \
   "identity_tools:release-validation: 15:required: 15:" \
   ":missing-artifacts: 0:missing-prohibited: 0:"

base_line "identity_tools reports release provenance field coverage" \
   "identity_tools:release-validation:" ":provenance-fields: 9:" \
   ":missing-provenance: 0"

base_line "release artifact registry parses" \
   "identity_tools:release-validation:" \
   ":missing-artifacts: 0:missing-prohibited: 0:missing-provenance: 0"

#  The registry parsing and the on-disk fixture inventory are asserted together:
#  ":missing-files: 0" is the tool's own statement that every fixture path listed
#  in registries/persisted-formats.json resolves to a file, and the loop below
#  re-checks that claim independently so the case cannot pass on a marker alone.
ok=1
if has_line "$BASELINE" "identity_tools:persisted-validation:" \
   ":missing-formats: 0:missing-fixtures: 0:" ":missing-files: 0"; then
   ok=0
   while IFS= read -r fixture; do
      if [ ! -f "$REPO/$fixture" ]; then
         note "persisted format registry parses and every listed fixture exists: missing fixture: $fixture"
         ok=1
      fi
   done < <(python3 -c '
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    document = json.load(handle)
for entry in document.get("formats", []):
    for fixture in entry.get("fixtures", []):
        print(fixture)
' "$REPO/registries/persisted-formats.json")
else
   note "persisted format registry parses and every listed fixture exists: baseline marker absent"
fi
record "persisted format registry parses and every listed fixture exists" "$ok"

base_line "identity_tools reports release report generation counts" \
   "identity_tools:release-reports:" ":write-failures:" ":skipped:"

base_line "identity_tools reports workflow validation counts" \
   "identity_tools:workflows: 9:gates: 43:" \
   ":missing-workflows: 0:missing-gates: 0:missing-orchestrator: 0:"

###############################################################################
#  Positive cases -- project_tools workflow manifest content
###############################################################################

ok=1
if file_has "$MANIFEST" 'required = "project_tools"' 'name = "release-check"' \
   && has_line "$BASELINE" "identity_tools:workflows:" \
      ":missing-workflows: 0:missing-gates: 0:missing-orchestrator: 0:missing-project-metadata: 0"; then
   ok=0
fi
record "project_tools workflow manifest parses and lists mandatory gates" "$ok"

manifest_gate "project_tools workflows include identity-tools-architecture gate" \
   "identity-tools-architecture"
manifest_gate "project_tools workflows include identity-tools-crypto-validation gate" \
   "identity-tools-crypto-validation"
manifest_gate "project_tools workflows include identity-tools-events gate" \
   "identity-tools-events"
manifest_gate "project_tools workflows include identity-tools-invariants gate" \
   "identity-tools-invariants"
manifest_gate "project_tools workflows include identity-tools-persisted-validation gate" \
   "identity-tools-persisted-validation"
manifest_gate "project_tools workflows include identity-tools-release-validation gate" \
   "identity-tools-release-validation"
manifest_gate "project_tools workflows include identity-tools-secret-leaks gate" \
   "identity-tools-secret-leaks"
manifest_gate "project_tools workflows include identity-tools-workflows gate" \
   "identity-tools-workflows"

###############################################################################
#  Summary
###############################################################################

printf 'gate-selftest:total:%d:passed:%d:failed:%d\n' "$TOTAL" "$PASSED" "$FAILED"

if [ "$FAILED" -ne 0 ]; then
   exit 1
fi
exit 0
