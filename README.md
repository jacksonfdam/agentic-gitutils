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
See [AGENTS.md](AGENTS.md) for the full schema contracts and
[`docs/DEMO.md`](docs/DEMO.md) for live output from every command against a
real public repo ([PoisonStack](https://github.com/jacksonfdam/poisonstack)).

## Install

```sh
git clone https://github.com/jacksonfdam/agentic-gitutils
cd agentic-gitutils
./install.sh                       # symlinks bin/* into ~/.local/bin
# or pick a different target:
INSTALL_DIR=/usr/local/bin ./install.sh
```

The installer also offers (interactively) to:

- add a discovery hint to `~/.claude/CLAUDE.md` so AI agents recognize these
  commands in every project (see [Agent discovery](#agent-discovery) below)
- check whether a newer version is available on `origin`

Skip the prompts with flags: `--yes`, `--no-hint`, `--no-update-check`.

Make sure the install dir is on your `PATH`. Any `bin/git-foo` then works as
`git foo`.

Uninstall: `./install.sh --uninstall` (also removes the agent hint).

## Versioning & updates

The current version is in [`VERSION`](VERSION) and surfaced via:

```sh
git utils version
```

To check for a newer version on `origin` and apply it safely:

```sh
git utils update                       # interactive: shows incoming commits, asks y/N
git utils update --check               # just report whether an update is available
git utils update --yes                 # apply without prompting
git utils update --require-signed      # refuse unless origin HEAD has a verified signature
```

To make signature verification the **default** for this install:

```sh
git -C "$(git utils version >/dev/null; dirname "$(readlink -f "$(command -v git-utils)")")/.." \
    config gitutils.requireSigned true
# or just: cd into the install dir and `git config gitutils.requireSigned true`
```

Signature verification accepts either:

- a signed commit at `origin/<branch>` (`git verify-commit`), or
- a signed annotated tag pointing at that commit (`git verify-tag`).

Both checks rely on your local GPG / SSH-signing keyring already containing
the public key of a signer you trust — `git utils` does not enforce *who*
signed, only that the signature is valid. Pair with `gpg --list-keys` (or
`gpg.ssh.allowedSignersFile`) for stricter trust.

**Security model for `update`:**

- Resolves the install dir from the binary's real path (no env-trust).
- Requires `origin` to be HTTPS, or SSH, to an allowlisted host
  (`github.com`, `gitlab.com`, `bitbucket.org`, `codeberg.org`).
- Refuses to update if the working tree has uncommitted changes.
- Refuses to update if your local branch is ahead of `origin`.
- Uses `git pull --ff-only` only — never merges or rebases unfamiliar history.
- Shows the incoming commits and asks for confirmation (skip with `--yes`).
- Optional `--require-signed` (or `git config gitutils.requireSigned true`)
  refuses to apply unless `origin/<branch>` has a verified signature on the
  commit *or* on an annotated tag pointing at it.

For a one-shot health check:

```sh
git utils doctor            # dependencies, PATH, remote, agent hint
```

## Agent discovery

Two layers make these commands available *and* discoverable to AI agents in
**every project on this machine**:

1. **PATH** — `install.sh` symlinks the commands into `~/.local/bin`, so any
   shell-launched agent inherits them just like `git` itself.
2. **Awareness** — `git utils install-agent-hint` writes a delimited block
   into `~/.claude/CLAUDE.md` listing the commands and pointing at
   [`AGENTS.md`](AGENTS.md) for the JSON schemas. Claude Code loads this file
   in every project automatically, so a new repo starts out with the agent
   already knowing the tools exist.

```sh
git utils install-agent-hint                 # default target: ~/.claude/CLAUDE.md
git utils install-agent-hint /path/to/file   # custom target
git utils uninstall-agent-hint               # symmetric removal
```

The block is wrapped in `<!-- gitutils:begin -->` / `<!-- gitutils:end -->`
markers — re-running `install-agent-hint` updates in place rather than
duplicating; existing file content is preserved.

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
| `git utils`          | Meta-command: `version`, `update`, `doctor`, agent-hint mgmt   |

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

## Release workflow

A GitHub Action at [`.github/workflows/release.yml`](.github/workflows/release.yml)
automates versioning. **On every push to `main`:**

1. Determines the bump level from conventional-commit prefixes since the
   last tag:
   - `feat!:` or `BREAKING CHANGE:` in any commit → **major**
   - `feat(scope)?:` in any commit → **minor**
   - everything else → **patch**
   - bot's own `chore(release):` commits are excluded from the analysis
2. Increments [`VERSION`](VERSION).
3. Commits the bump as `chore(release): bump to vX.Y.Z [skip release]`.
4. Creates an **annotated tag** `vX.Y.Z`.
5. Pushes both the commit and the tag.
6. Opens a GitHub Release with auto-generated notes via `gh release create`.

**Recursion is prevented two ways:**

- `paths-ignore: VERSION` on the trigger — the bot's own commit touches only
  `VERSION` and never re-fires the workflow.
- `[skip release]` marker on the bot's commit message, checked by the job's
  `if:` filter.

**Skipping a release** for a specific push: include `[skip release]` in the
commit subject or body.

**Permissions**: the workflow uses the default `GITHUB_TOKEN` with
`permissions: contents: write`. No external secrets needed for the basic
flow. If your `main` is protected by required reviews, the workflow's push
will be rejected — either exempt the `github-actions[bot]` user from the
protection or move the bump to a PR-based flow.

**Signing tags**: the default workflow creates unsigned annotated tags. To
sign them, add a GPG (or SSH-signing) key as a repo secret and add
`run: git config user.signingkey …` plus `-s` to the `git tag` call. Once
tags are signed, downstream users of `git utils update --require-signed`
will accept the release.

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
