#!/usr/bin/env bash
# -f disables pathname expansion so an unquoted "*" (or any glob) in an
# input token is treated literally, not expanded against the CWD's files;
# word-splitting (the unquoted `for kv in $REQUIRED` loops) is still wanted.
set -fuo pipefail

REQUIRED="${REQUIRED:-}"
OPTIONAL="${OPTIONAL:-}"
FAIL_ON_CANCELLED="${FAIL_ON_CANCELLED:-}"

if [ -z "${REQUIRED//[[:space:]]/}" ]; then
  echo "::error::ci-result-gate: 'required' is empty — refusing to pass a gate with no required jobs"
  exit 1
fi

fail=0
for kv in $REQUIRED; do
  n=${kv%%=*}; r=${kv#*=}
  if [ "$r" != "success" ]; then echo "required $n=$r"; fail=1; fi
done
for kv in $OPTIONAL; do
  n=${kv%%=*}; r=${kv#*=}
  if [ "$r" != "success" ] && [ "$r" != "skipped" ]; then echo "optional $n=$r"; fail=1; fi
done
for kv in $FAIL_ON_CANCELLED; do
  n=${kv%%=*}; r=${kv#*=}
  if [ "$r" = "cancelled" ]; then echo "$n cancelled"; fail=1; fi
done
exit $fail
