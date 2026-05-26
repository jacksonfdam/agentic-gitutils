#!/usr/bin/env bash
# tests/smoke.sh — exercise each git-utils command against a throwaway repo.
#
# Run:
#   ./tests/smoke.sh
#
# Exit non-zero on the first failure. Pretty-prints what each command emits.

set -euo pipefail

HERE="$(cd "$(dirname "$0")"/.. && pwd)"
PATH="$HERE/bin:$PATH"
export PATH

# When any command in the script fails, print the line and the last command.
# jq -e exits non-zero silently when an assertion is false, which otherwise
# leaves the user staring at a bare prompt.
on_err() {
  local rc=$?
  echo
  echo "FAIL  exit=$rc  line=$BASH_LINENO  cmd: $BASH_COMMAND" >&2
  exit "$rc"
}
trap on_err ERR

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$TMP"
git init -q -b main

git config user.email "smoke@test.local"
git config user.name  "Smoke Tester"

echo "alpha"  > alpha.txt
echo "beta"   > beta.txt
git add .
git commit -q -m "init: alpha & beta"

echo "alpha v2"   > alpha.txt
git commit -qam "tweak alpha"

git checkout -q -b feature/wild
echo "gamma"  > gamma.txt
git add gamma.txt
git commit -q -m "feat: add gamma — with \"quotes\" and a%percent"

git checkout -q main
echo "alpha v3" > alpha.txt
echo "delta"    > delta.txt
git add .

step() { printf "\n\033[1m== %s ==\033[0m\n" "$1"; }

step "git json-log"
# main has 2 commits (init alpha&beta, tweak alpha); feature/wild adds 1 on its own branch.
git json-log -n 5 | jq -e 'type == "array" and length == 2' >/dev/null
git json-log -n 5 | jq -e '.[0].subject == "tweak alpha"' >/dev/null
git json-log -n 5 | jq -e '.[0].author.name == "Smoke Tester"' >/dev/null
git json-log --all -n 10 | jq -e 'length == 3' >/dev/null

step "git json-status"
out=$(git json-status)
echo "$out" | jq -e '.branch.head == "main"' >/dev/null
echo "$out" | jq -e '.files | length >= 1' >/dev/null

step "git json-diff-stat"
git json-diff-stat --cached | jq -e 'type == "array"' >/dev/null

step "git json-diff"
out=$(git json-diff --cached)
echo "$out" | jq -e 'type == "array"' >/dev/null
echo "$out" | jq -e '[.[].new_path] | index("delta.txt") != null' >/dev/null
echo "$out" | jq -e '[.[] | select(.new_path == "alpha.txt")][0].hunks[0].lines | length > 0' >/dev/null
echo "$out" | jq -e '[.[] | select(.new_path == "delta.txt")][0].mode == "added"' >/dev/null

step "git json-branches"
git json-branches | jq -e '[.[].name] | contains(["main", "feature/wild"])' >/dev/null

step "git recent"
git recent 5 | jq -e 'type == "array" and length >= 2' >/dev/null
git recent 5 --plain | grep -q "alpha.txt"

step "git stats"
git stats | jq -e '.head.branch == "main" and .commits_total == 2' >/dev/null
git stats --all | jq -e '.commits_total == 3' >/dev/null
git stats | jq -e '.authors | map(.name) | index("Smoke Tester") != null' >/dev/null

echo
echo "all smoke tests passed in $TMP"
