# AGENTS.md

Notes for LLM-based agents (and the humans wiring them up) consuming the
commands in this repo.

## Why these commands exist for you

Default git porcelain output is shaped for humans. Subjects can contain quotes,
paths can contain spaces, diff lines can collide with section markers, etc.
The `git json-*` commands here produce **stable, structured JSON** so an agent
can rely on field names and shapes rather than line-based regex.

## Stable contracts

The schemas below are the contract. If a future change has to break one of
these, it'll bump a major in [CHANGELOG.md](CHANGELOG.md) and the command
will gain a `--schema=N` flag for the previous shape.

### `git json-log` → `Array<Commit>`

```ts
type Commit = {
  commit: string;          // full SHA
  abbreviated: string;     // short SHA
  parents: string[];       // empty for root commits
  refs: string[];          // decorate refs, in commit order
  author:    { name: string; email: string; date: string };   // ISO-8601
  committer: { name: string; email: string; date: string };
  subject: string;
  body: string;            // may be ""
};
```

### `git json-status` → `Status`

```ts
type Status = {
  branch: {
    head: string;          // current branch ("" if detached)
    oid:  string;
    upstream: string | null;
    ahead:  number;
    behind: number;
  };
  files: Array<{
    kind: "changed" | "renamed";
    index: string;         // 1-char status code, "." = unchanged
    worktree: string;      // 1-char status code
    submodule: string;     // 4-char submodule status
    mode_head?: string; mode_index?: string; mode_worktree?: string;
    oid_head?: string;  oid_index?: string;
    path: string;
    renamed_from?: string;
    rename_score?: string;
  }>;
  unmerged: Array<{ kind: "unmerged"; index: string; worktree: string; path: string }>;
  untracked: string[];
  ignored:   string[];
};
```

### `git json-diff-stat` → `Array<NumStat>`

```ts
type NumStat = {
  added: number;     // 0 for binary files
  deleted: number;   // 0 for binary files
  binary: boolean;
  path: string;
};
```

### `git json-diff` → `Array<FileDiff>`

```ts
type FileDiff = {
  from: string; to: string;       // "a/<path>", "b/<path>"
  old_path: string; new_path: string;
  mode: "modified" | "added" | "deleted" | "renamed" | "binary";
  old_mode: string | null; new_mode: string | null;
  old_oid:  string | null; new_oid:  string | null;
  similarity: number | null;      // 0..100, only for renames
  hunks: Array<{
    old_start: number; old_lines: number;
    new_start: number; new_lines: number;
    header: string;                // raw @@ line
    lines: Array<{
      op: " " | "-" | "+";
      old_no: number | null;       // null on "+" lines
      new_no: number | null;       // null on "-" lines
      text: string;                // without the leading op char
    }>;
  }>;
};
```

### `git json-branches` → `Array<Branch>`

```ts
type Branch = {
  refname: string;          // refs/heads/foo or refs/remotes/origin/foo
  name: string;             // foo or origin/foo
  kind: "local" | "remote";
  is_head: boolean;
  oid: string;
  upstream: string | null;
  ahead: number;
  behind: number;
  author_name: string;
  author_email: string;     // angle brackets stripped
  committer_date: string;   // ISO-8601-strict
  subject: string;
};
```

### `git recent` → `Array<TouchedFile>`

```ts
type TouchedFile = {
  path: string;
  touches: number;          // count within the matched commit window
  last_commit: string;      // short SHA
  last_date: string;        // ISO-8601-strict
  last_subject: string;
};
```

### `git json-blame` → `Array<BlameLine>`

```ts
type BlameLine = {
  line: number;          // final line number (1-based)
  content: string;
  commit: string;        // full SHA
  abbreviated: string;
  orig_line: number;     // line in the originating commit
  author: string;
  author_email: string;
  author_date: string;   // ISO-8601 with offset
  committer: string;
  committer_email: string;
  committer_date: string;
  summary: string;       // commit subject
  filename: string;      // path in the originating commit
  previous: string | null;  // "<sha> <path>" or null
  boundary: boolean;     // true when this is the oldest commit in scope
};
```

### `git json-show` → `CommitFull`

```ts
type CommitFull = {
  commit: string;
  abbreviated: string;
  parents: string[];
  refs: string[];
  author:    { name: string; email: string; date: string };
  committer: { name: string; email: string; date: string };
  subject: string;
  body: string;
  stats: { files_changed: number; insertions: number; deletions: number };
  files: FileDiff[];     // same shape as `git json-diff` entries
};
```

### `git json-range` → `Range`

```ts
type Range = {
  base: string;          // input ref (e.g. "main")
  head: string;          // input ref (e.g. "HEAD")
  base_oid: string;
  head_oid: string;
  merge_base: string | null;
  is_symmetric: boolean; // true if invoked with "<base>...<head>"
  commits: Commit[];     // shape from git-json-log
  files: Array<{
    path: string;
    added: number;
    deleted: number;
    binary: boolean;
    mode: "added" | "deleted" | "modified" | "renamed" | "type-changed" | "unmerged";
  }>;
  authors: Array<{ name: string; email: string; commits: number }>;
  stats: {
    commits: number;
    files_changed: number;
    insertions: number;
    deletions: number;
  };
};
```

### `git json-conflicts` → `Array<ConflictedFile>`

```ts
type ConflictedFile = {
  path: string;
  conflict_style: "merge" | "diff3";
  conflicts: Array<{
    start_line: number;          // 1-based line of <<<<<<<
    end_line: number;            // 1-based line of >>>>>>>
    ours_label: string;          // label after <<<<<<<, e.g. "HEAD"
    base_label: string | null;   // label after |||||||, diff3 only
    theirs_label: string;        // label after >>>>>>>
    ours: string[];
    base: string[] | null;       // present only with diff3
    theirs: string[];
    context_before: string[];    // up to 3 lines preceding the conflict
    context_after:  string[];    // up to 3 lines following the conflict
  }>;
};
```

### `git stats` → `RepoSummary`

```ts
type RepoSummary = {
  head: { branch: string | null; oid: string | null; subject: string | null };
  remotes: string[];
  commits_total: number;
  branches: { local: number; remote: number };
  tags: number;
  authors: Array<{ name: string; email: string; commits: number }>;
  files_top: Array<{ path: string; touches: number }>;
  first_commit_date: string | null;
  last_commit_date:  string | null;
};
```

### `git utils` — meta-command (text output, not JSON)

This one is not a data emitter; it manages the install itself. Agents
should mostly leave it alone, with two exceptions:

- `git utils version` — print the installed semver. Useful when an agent
  needs to record which version of the toolkit it relied on for a result.
- `git utils doctor` — quick environment check. Helpful when a JSON command
  returns nothing unexpected, to confirm the toolkit is actually wired up.

Never invoke `git utils update` from an agent without explicit user
consent — it changes the install on disk.

## Tips for agent prompts

- **Always validate before assuming**: pipe through `| jq -e 'type == "array"'`
  in scripted agents so a malformed run fails fast rather than silently.
- **Prefer `--cached` or explicit ranges** in `git json-diff` so the agent
  reasons about a deterministic snapshot, not the live working tree.
- **Cap history** with `-n` on `git json-log` / `git recent`. The schemas
  are stable but the output size is not.
- **Bring your own filter**: combine with [`gron`](https://github.com/tomnomnom/gron)
  for path-style grepping, e.g.
  `git json-log -n 50 | gron | grep author.email | gron --ungron`.
