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
git json-log -n 3 | jq '.[0] | {subject, author: .author.name, parents}' >/dev/null
git json-log -n 3 | jq -e '. | type == "array" and length == 3' >/dev/null

step "git json-status"
out=$(git json-status)
echo "$out" | jq -e '.branch.head == "main"' >/dev/null
echo "$out" | jq -e '.files | length >= 1' >/dev/null

step "git json-diff-stat"
git json-diff-stat --cached | jq -e 'type == "array"' >/dev/null

step "git json-diff"
git json-diff --cached | jq -e '
  type == "array"
  and ([.[] | .new_path] | index("delta.txt") != null)
  and ([.[] | select(.new_path == "alpha.txt") | .hunks[0].lines | length] | first) > 0
' >/dev/null

step "git json-branches"
git json-branches | jq -e '[.[].name] | contains(["main", "feature/wild"])' >/dev/null

step "git recent"
git recent 5 | jq -e 'type == "array" and length >= 2' >/dev/null
git recent 5 --plain | grep -q "alpha.txt"

step "git stats"
git stats | jq -e '.head.branch == "main" and .commits_total >= 3' >/dev/null

echo
echo "all smoke tests passed in $TMP"
