#!/usr/bin/env bash
# tools/build-demo.sh — render docs/DEMO.md by running every git-utils
# command against a target repo. Defaults to PoisonStack. Re-run after
# significant changes.
#
# Usage: ./tools/build-demo.sh [<path-to-target-repo>]

set -euo pipefail

HERE="$(cd "$(dirname "$0")"/.. && pwd)"
DEMO_REPO="${1:-/Users/jackson.mafra/Downloads/Projects/PoisonStack}"
OUT="$HERE/docs/DEMO.md"

if [[ ! -d "$DEMO_REPO/.git" ]]; then
  echo "error: $DEMO_REPO is not a git repository." >&2
  exit 1
fi

export PATH="$HERE/bin:$PATH"
mkdir -p "$(dirname "$OUT")"

# Resolve repo metadata once so we can quote it in the doc.
repo_name=$(basename "$DEMO_REPO")
remote_url=$(git -C "$DEMO_REPO" remote get-url origin 2>/dev/null || echo "(no remote)")
total_commits=$(git -C "$DEMO_REPO" rev-list --count HEAD)
default_branch=$(git -C "$DEMO_REPO" symbolic-ref --short HEAD 2>/dev/null || echo "?")
sample_recent_commit=$(git -C "$DEMO_REPO" log -n 1 --pretty='%h' --skip 2)  # 3rd most recent
sample_range="HEAD~3..HEAD~2"
small_file=$(git -C "$DEMO_REPO" ls-tree -r --name-only HEAD \
  | grep -E '\.md$|\.txt$|README' | head -n1)

# --- helpers -------------------------------------------------------------

emit() { printf '%s\n' "$@" >> "$OUT"; }

cap() {
  # run a command in the demo repo, capture its output, write into a fenced
  # block. The optional jq filter trims to a representative slice.
  local label="$1" lang="$2" jq_slice="$3"
  shift 3
  emit "**Command**" "" '```sh' "cd $repo_name" "$ ${*}" '```' "" "**Output** (sliced for the demo)" ''
  emit '```'"$lang"
  (cd "$DEMO_REPO" && "$@") 2>&1 | (
    if [[ -n "$jq_slice" ]]; then jq -M "$jq_slice"; else cat; fi
  ) | head -n 80 >> "$OUT" || true
  emit '```' ''
}

# --- header --------------------------------------------------------------

cat > "$OUT" <<EOF
# Demo: \`git-utils\` against a real repo

Every command below was run against [\`$repo_name\`]($remote_url),
$total_commits commits on \`$default_branch\`. Output is from a live run;
each block is sliced (typically the first record or the first \`head -n 80\`
lines) so the doc stays readable.

Re-render this file with:

\`\`\`sh
./tools/build-demo.sh /path/to/some/repo
\`\`\`

## Setup

\`\`\`sh
# from this gitutils checkout
./install.sh
# then in any git repo on disk:
cd ~/path/to/your/project
git utils version
\`\`\`

---

EOF

# --- per-command sections -----------------------------------------------

emit "## \`git utils\` — meta-command" ""
cap "version" "" "" git utils version
emit "Then:" "" '```sh' '$ git utils doctor       # full health check' '$ git utils update --check    # is there a newer version on origin?' '```' '' '---' ''

emit "## \`git json-log\` — commits as JSON" ""
cap "log" "json" '.[0]' git json-log -n 3

emit "Useful slices:" "" '```sh' '$ git json-log -n 50 | jq -r ".[] | \"\(.abbreviated)  \(.author.name)  \(.subject)\""' '$ git json-log --since=1.month | jq "[.[].author.email] | unique"' '```' '' '---' ''

emit "## \`git json-status\` — working tree state as JSON" ""
cap "status" "json" '' git json-status
emit "" '---' ''

emit "## \`git json-diff-stat\` — \`--numstat\` as JSON" ""
cap "diff-stat" "json" '.[0:5]' git json-diff-stat "$sample_range"
emit "" '---' ''

emit "## \`git json-diff\` — full unified diff parsed into hunks/lines" ""
cap "diff" "json" '.[0] | {old_path, new_path, mode, hunks: (.hunks | length), first_hunk: .hunks[0] | {header, lines: (.lines | length)}}' git json-diff "$sample_range"
emit "" '---' ''

emit "## \`git json-branches\` — local + remote branches with metadata" ""
cap "branches" "json" '.[0:3]' git json-branches
emit "" '---' ''

emit "## \`git json-blame\` — per-line authorship" ""
if [[ -n "$small_file" ]]; then
  cap "blame" "json" '.[0:3]' git json-blame "$small_file"
else
  emit '(no suitable file found in the target repo for a blame demo)' ''
fi
emit "" '---' ''

emit "## \`git json-show\` — one commit, fully expanded" ""
cap "show" "json" '{commit, abbreviated, parents, author, stats, files: [.files[] | {new_path, mode, hunks: (.hunks|length)}]}' git json-show "$sample_recent_commit"
emit "" '---' ''

emit "## \`git json-range\` — what changed between two refs" ""
cap "range" "json" '{base, head, merge_base, stats, files: (.files[0:5]), authors}' git json-range "HEAD~5..HEAD"
emit "" '---' ''

emit "## \`git json-conflicts\` — currently-unmerged files" ""
cap "conflicts" "json" '' git json-conflicts
emit "Empty in this repo (nothing currently being merged). The shape would be:" "" '```json' '[' '  {' '    "path": "src/foo.ts",' '    "conflict_style": "diff3",' '    "conflicts": [' '      {' '        "start_line": 10, "end_line": 25,' '        "ours_label": "HEAD", "theirs_label": "feature/bar",' '        "ours":   ["..."], "base": ["..."], "theirs": ["..."],' '        "context_before": ["..."], "context_after":  ["..."]' '      }' '    ]' '  }' ']' '```' '' '---' ''

emit "## \`git recent\` — recently touched files" ""
cap "recent" "json" '.[0:8]' git recent 20
emit "" '---' ''

emit "## \`git stats\` — repo summary" ""
cap "stats" "json" '{head, commits_total, branches, authors: .authors[0:3], files_top: .files_top[0:5], first_commit_date, last_commit_date}' git stats
emit "" '---' ''

emit "## \`git tui-diff\` — side-by-side terminal viewer" ""
emit "Renders a diff for human review in the terminal. The block below is the" \
     "uncolored output (real runs are ANSI-colored and auto-paged via \`less\`)." ""
emit '```text'
(cd "$DEMO_REPO" && git tui-diff --no-pager --no-color --width 100 "$sample_range") 2>&1 | head -n 40 >> "$OUT" || true
emit '```' '' '---' ''

emit "## \`git visual-diff\` — side-by-side HTML viewer" ""
emit '```sh' "cd $repo_name" '$ git visual-diff HEAD~1..HEAD          # opens in your browser' '$ git visual-diff --print HEAD~1..HEAD  # write the path, don'"'"'t open' '```' '' \
"The viewer is a single self-contained HTML file with two-column rendering," \
"highlight.js syntax highlighting, and prev/next file navigation. Read-only." \
"" '---' ''

emit "## See also" "" \
"- [\`AGENTS.md\`](../AGENTS.md) — TypeScript-style schema for every JSON-emitting command" \
"- [\`CHANGELOG.md\`](../CHANGELOG.md) — release notes" \
"- [\`README.md\`](../README.md) — install, usage, security model, agent discovery"

echo "wrote $OUT"
