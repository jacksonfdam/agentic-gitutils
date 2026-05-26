# git-utils

Small collection of custom `git` subcommands that emit **JSON**, making git
output greppable, pipeable, and agent-friendly.

## Why JSON?

`git log`, `git diff`, and `git status` emit text shaped for humans. That makes
them painful to:

- Pipe into `jq`, `gron`, `fx`, or any downstream JSON tool.
- Feed to LLM agents that parse structured data more reliably than free-form text.
- Compare across runs or commits without brittle line-based parsing.


These commands produce stable JSON so the rest of your tooling can stop guessing.
See [AGENTS.md](AGENTS.md) for the full schema contracts.

## Install

```sh
git clone https://github.com/jacksonfdam/agentic-gitutils
cd agentic-gitutils
./install.sh                       # symlinks bin/* into ~/.local/bin
# or pick a different target:
INSTALL_DIR=/usr/local/bin ./install.sh
```

Make sure the install dir is on your `PATH`. Any `bin/git-foo` then works as
`git foo`.

Uninstall: `./install.sh --uninstall`.

### Requirements

- `git` ≥ 2.30 (porcelain v2 fields)
- `jq` ≥ 1.6
- `python3` ≥ 3.8 (used by `git-json-diff` and `git-recent`)
- `bash` or `zsh`

## Commands

| Command              | What it does                                                   |
|----------------------|----------------------------------------------------------------|
| `git json-log`       | `git log` as a JSON array of structured commits                |
| `git json-status`    | Working-tree status with branch ahead/behind, untracked, etc.  |
| `git json-diff`      | Full unified diff parsed into files/hunks/lines                |
| `git json-diff-stat` | `--numstat` as JSON (`added`/`deleted`/`binary`/`path`)        |
| `git json-branches`  | Local + remote branches with metadata                          |
| `git json-blame`     | Per-line authorship JSON (commit, author, date, summary)       |
| `git json-show`      | One commit fully expanded — metadata + per-file diff + stats   |
| `git json-range`     | Summary between two refs — commits, files, authors, stats      |
| `git json-conflicts` | Currently-unmerged files with parsed conflict markers          |
| `git recent`         | Recently-touched files, with touch count + last-seen metadata  |
| `git stats`          | Repo summary (commits, branches, top authors, top files)       |
| `git visual-diff`    | Side-by-side HTML diff viewer (read-only, opens in browser)    |
| `git tui-diff`       | Side-by-side terminal diff viewer (ANSI, pipes through `less`) |

Run any command with no arguments to see the default; forward extra args to
the underlying `git` invocation where it makes sense.

## Examples

### Find recent commits by an author and list their subjects

```sh
git json-log --since=2.weeks --author=jackson \
  | jq -r '.[] | "\(.abbreviated) \(.subject)"'
```

### What files did I touch most this month, and when last?

```sh
git recent --since=1.month \
  | jq '.[] | select(.touches > 1) | { path, touches, last_date }'
```

### Inspect the staged diff structurally

```sh
git json-diff --cached \
  | jq '.[] | { new_path, mode, hunks: (.hunks|length), lines: ([.hunks[].lines[]] | length) }'
```

### Lines added across the branch

```sh
git json-diff-stat main...HEAD \
  | jq '[.[] | .added] | add'
```

### Branches behind their upstream

```sh
git json-branches --local \
  | jq '.[] | select(.behind > 0) | { name, behind, upstream }'
```

### Pair with gron for path-style grepping

```sh
git json-log -n 50 | gron | grep '\.author\.email' | sort -u
```

### Quick repo overview

```sh
git stats | jq '{ commits_total, branches, top_author: .authors[0] }'
```

### Who wrote each line of a file?

```sh
git json-blame src/foo.ts \
  | jq -r '.[] | "\(.line)\t\(.abbreviated)\t\(.author)\t\(.summary)"'
```

### Single commit, fully expanded

```sh
git json-show HEAD \
  | jq '{ subject, stats, files: [.files[] | { path: .new_path, mode }] }'
```

### What changed since the last release tag?

```sh
git json-range "v1.2.0..HEAD" \
  | jq '{ commits: .stats.commits, files: .stats.files_changed,
          authors: [.authors[] | .name],
          biggest: ([.files[] | { path, lines: (.added + .deleted) }] | sort_by(-.lines) | .[0:5]) }'
```

### List currently-conflicted files structurally

```sh
git json-conflicts \
  | jq '.[] | { path, n: (.conflicts | length),
                first_ours: .conflicts[0].ours, first_theirs: .conflicts[0].theirs }'
```

### Open a side-by-side viewer in the browser

```sh
git visual-diff                       # working tree vs index
git visual-diff --cached              # staged
git visual-diff main..feature         # branch range
git visual-diff main -- src/foo.ts    # working file vs main
git visual-diff v1.2.0..HEAD          # since-tag overview

# Useful flags:
#   --no-open      don't launch the browser
#   --print        print the HTML path to stdout
#   --output PATH  write the HTML to PATH instead of $TMPDIR
```

Navigate files with ←/→ or `j`/`k`; syntax highlighting via highlight.js
(loaded from CDN). The viewer is read-only — there's no UI to accept or
reject changes.

### Same idea, but in the terminal

```sh
git tui-diff                          # working tree vs index, opens in less
git tui-diff --cached
git tui-diff main..feature
git tui-diff main -- src/foo.ts
git tui-diff v1.2.0..HEAD

# Useful flags:
#   --no-pager     write straight to stdout, no `less`
#   --no-color     suppress ANSI escapes
#   --width N      force a specific column width
```

ANSI side-by-side render, automatically piped through `less -RFX`. Inside
`less`: `q` to quit, `/` to search, `n` / `N` for next / previous match.
Width auto-detected from the terminal; respects `NO_COLOR=1`.

## Layout

```
bin/             # individual git-<command> executables
tests/smoke.sh   # runs every command against a throwaway repo
install.sh       # symlinks bin/* into $INSTALL_DIR (default ~/.local/bin)
AGENTS.md        # JSON contracts for agent consumers
```

## Testing

```sh
./tests/smoke.sh
```

Creates a temp repo, exercises every command, asserts shape with `jq -e`,
and cleans up.

Inspired by:

- [gron](https://github.com/tomnomnom/gron) — Make JSON greppable.
- [diffparser](https://github.com/petereon/diffparser) — Parse `git diff` to JSON.
- [git log → JSON via jq](https://til.simonwillison.net/jq/git-log-json) — Simon Willison.
- [Cali0707/git-utils](https://github.com/Cali0707/git-utils) — Reference custom-command repo.
- [Custom git commands](https://www.calummurray.ca/blog/custom-git-commands).


## Contributing

- New commands go in `bin/git-<name>`, must be executable, must emit valid
  JSON to stdout unless explicitly text-mode.
- Document the schema in [AGENTS.md](AGENTS.md).
- Add a smoke check in [`tests/smoke.sh`](tests/smoke.sh).

## License

[MIT](LICENSE)
