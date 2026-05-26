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
- `git recent` — recently touched files, with touch count + last-seen metadata.
- `git stats` — repo summary (commits, branches, top authors, top files).
- `install.sh` — idempotent symlink installer with `--uninstall`.
- `tests/smoke.sh` — exercises every command against a temp repo.
