# Changelog

All notable changes to this project will be documented in this file. The
format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
this project aims to follow [SemVer](https://semver.org/) for its JSON
contracts (see [AGENTS.md](AGENTS.md)).

## [Unreleased]

### Added

- `git json-log` — `git log` as a JSON array.
- `git json-status` — working-tree status with branch ahead/behind.
- `git json-diff` — unified diff parsed into files/hunks/lines.
- `git json-diff-stat` — `git diff --numstat` as JSON.
- `git json-branches` — local + remote branches with metadata.
- `git json-blame` — per-line authorship with commit/author/date/summary.
- `git json-show` — one commit fully expanded (metadata + per-file diff + stats).
- `git json-range` — summary between two refs (commits, files, authors, stats).
- `git json-conflicts` — currently-unmerged files with parsed conflict markers.
- `git recent` — recently touched files, with touch count + last-seen metadata.
- `git stats` — repo summary (commits, branches, top authors, top files).
- `git visual-diff` — side-by-side HTML diff viewer with syntax highlighting and prev/next file navigation. View-only.
- `git tui-diff` — side-by-side terminal diff viewer with ANSI colors, auto-paged through `less`. View-only.
- `install.sh` — idempotent symlink installer with `--uninstall`.
- `tests/smoke.sh` — exercises every command against a temp repo.
