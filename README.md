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
git clone <this repo>
cd git-utils
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
| `git recent`         | Recently-touched files, with touch count + last-seen metadata  |
| `git stats`          | Repo summary (commits, branches, top authors, top files)       |

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
