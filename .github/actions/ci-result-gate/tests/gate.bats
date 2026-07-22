#!/usr/bin/env bats

setup() {
  GATE="${BATS_TEST_DIRNAME}/../gate.sh"
  REQUIRED=""
  OPTIONAL=""
  FAIL_ON_CANCELLED=""
}

run_gate() {
  export REQUIRED="$1" OPTIONAL="$2" FAIL_ON_CANCELLED="$3"
  run bash "$GATE"
}

# --- required ---

@test "required: all success passes" {
  run_gate "check=success test=success" "" ""
  [ "$status" -eq 0 ]
}

@test "required: one failure fails" {
  run_gate "check=failure test=success" "" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"required check=failure"* ]]
}

@test "required: cancelled fails" {
  run_gate "check=cancelled" "" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"required check=cancelled"* ]]
}

@test "required: empty result (check=) fails" {
  run_gate "check=" "" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"required check="* ]]
}

@test "required: bare token with no = fails" {
  run_gate "check" "" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"required check=check"* ]]
}

@test "required: two failing prints both names" {
  run_gate "check=failure test=cancelled" "" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"required check=failure"* ]]
  [[ "$output" == *"required test=cancelled"* ]]
}

# --- optional ---

@test "optional: skipped passes" {
  run_gate "check=success" "smoke=skipped" ""
  [ "$status" -eq 0 ]
}

@test "optional: success passes" {
  run_gate "check=success" "smoke=success" ""
  [ "$status" -eq 0 ]
}

@test "optional: failure fails" {
  run_gate "check=success" "smoke=failure" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"optional smoke=failure"* ]]
}

@test "optional: cancelled fails" {
  run_gate "check=success" "smoke=cancelled" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"optional smoke=cancelled"* ]]
}

# --- fail-on-cancelled ---

@test "fail-on-cancelled: cancelled fails" {
  run_gate "check=success" "" "e2e=cancelled"
  [ "$status" -eq 1 ]
  [[ "$output" == *"e2e cancelled"* ]]
}

@test "fail-on-cancelled: success passes" {
  run_gate "check=success" "" "e2e=success"
  [ "$status" -eq 0 ]
}

@test "fail-on-cancelled: skipped passes" {
  run_gate "check=success" "" "e2e=skipped"
  [ "$status" -eq 0 ]
}

@test "fail-on-cancelled: unset passes" {
  run_gate "check=success" "" ""
  [ "$status" -eq 0 ]
}

# --- hardening: empty required ---

@test "hardening: empty required fails" {
  run_gate "" "" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"::error::ci-result-gate: 'required' is empty"* ]]
}

@test "hardening: whitespace-only required fails" {
  run_gate "   " "" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"::error::ci-result-gate: 'required' is empty"* ]]
}

@test "hardening: literal '*' in required is not pathname-expanded" {
  local dir="$BATS_TEST_TMPDIR/glob-check"
  mkdir -p "$dir"
  touch "$dir/alpha" "$dir/beta"
  cd "$dir"
  run_gate "check=success *" "" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"required *=*"* ]]
  [[ "$output" != *"alpha"* ]]
  [[ "$output" != *"beta"* ]]
}

@test "hardening: unset required fails" {
  unset REQUIRED
  export OPTIONAL="" FAIL_ON_CANCELLED=""
  run bash "$GATE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"::error::ci-result-gate: 'required' is empty"* ]]
}

# --- combined ---

@test "combined: all three populated and passing" {
  run_gate "check=success test=success" "smoke=skipped" "e2e=success"
  [ "$status" -eq 0 ]
}

@test "combined: a failure in each category fails" {
  run_gate "check=failure" "smoke=failure" "e2e=cancelled"
  [ "$status" -eq 1 ]
  [[ "$output" == *"required check=failure"* ]]
  [[ "$output" == *"optional smoke=failure"* ]]
  [[ "$output" == *"e2e cancelled"* ]]
}

# --- regression: real consumer call shapes ---

@test "regression: breadboard call shape passes" {
  run_gate "check=success test=success" "smoke=skipped py-tests=skipped changes=success" ""
  [ "$status" -eq 0 ]
}

@test "regression: TaipanMiner-webui-ws call shape passes" {
  run_gate "webui-check=success native-test=success" "build=skipped py-tests=skipped changes=success" "e2e=success"
  [ "$status" -eq 0 ]
}
