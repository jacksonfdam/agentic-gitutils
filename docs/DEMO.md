# Demo: `git-utils` against a real repo

Every command below was run against [`PoisonStack`](https://github.com/jacksonfdam/poisonstack.git),
15 commits on `main`. Output is from a live run;
each block is sliced (typically the first record or the first `head -n 80`
lines) so the doc stays readable.

Re-render this file with:

```sh
./tools/build-demo.sh /path/to/some/repo
```

## Setup

```sh
# from this gitutils checkout
./install.sh
# then in any git repo on disk:
cd ~/path/to/your/project
git utils version
```

---

## `git utils` — meta-command

**Command**

```sh
cd PoisonStack
$ git utils version
```

**Output** (sliced for the demo)

```
1.0.0
```

Then:

```sh
$ git utils doctor       # full health check
$ git utils update --check    # is there a newer version on origin?
```

---

## `git json-log` — commits as JSON

**Command**

```sh
cd PoisonStack
$ git json-log -n 3
```

**Output** (sliced for the demo)

```json
{
  "commit": "93d47b34d9cbc6904161c1f9d444f52df783c830",
  "abbreviated": "93d47b3",
  "parents": [
    "cfd889718308a4114c5fb8d32a60c68a8d0689fd"
  ],
  "refs": [
    "HEAD -> main",
    "origin/main",
    "origin/HEAD"
  ],
  "author": {
    "name": "Jackson Mafra",
    "email": "jackson.mafra@umain.com",
    "date": "2026-05-16T11:43:46+02:00"
  },
  "committer": {
    "name": "Jackson Mafra",
    "email": "jackson.mafra@umain.com",
    "date": "2026-05-16T11:43:46+02:00"
  },
  "subject": "docs: add four-part article series in EN and PT-BR",
  "body": ""
}
```

Useful slices:

```sh
$ git json-log -n 50 | jq -r ".[] | \"\(.abbreviated)  \(.author.name)  \(.subject)\""
$ git json-log --since=1.month | jq "[.[].author.email] | unique"
```

---

## `git json-status` — working tree state as JSON

**Command**

```sh
cd PoisonStack
$ git json-status
```

**Output** (sliced for the demo)

```json
{
  "branch": {
    "oid": "93d47b34d9cbc6904161c1f9d444f52df783c830",
    "head": "main",
    "upstream": "origin/main",
    "ahead": 0,
    "behind": 0
  },
  "files": [],
  "unmerged": [],
  "untracked": [
    "articles/assets/hero.svg"
  ],
  "ignored": [
    ".DS_Store",
    "articles/.DS_Store"
  ]
}
```


---

## `git json-diff-stat` — `--numstat` as JSON

**Command**

```sh
cd PoisonStack
$ git json-diff-stat HEAD~3..HEAD~2
```

**Output** (sliced for the demo)

```json
[
  {
    "added": 56,
    "deleted": 736,
    "binary": false,
    "path": "README.md"
  }
]
```


---

## `git json-diff` — full unified diff parsed into hunks/lines

**Command**

```sh
cd PoisonStack
$ git json-diff HEAD~3..HEAD~2
```

**Output** (sliced for the demo)

```json
{
  "old_path": "README.md",
  "new_path": "README.md",
  "mode": "modified",
  "hunks": 1,
  "first_hunk": {
    "header": "@@ -1,764 +1,84 @@",
    "lines": 820
  }
}
```


---

## `git json-branches` — local + remote branches with metadata

**Command**

```sh
cd PoisonStack
$ git json-branches
```

**Output** (sliced for the demo)

```json
[
  {
    "refname": "refs/heads/main",
    "name": "main",
    "oid": "93d47b34d9cbc6904161c1f9d444f52df783c830",
    "kind": "local",
    "is_head": true,
    "upstream": "origin/main",
    "ahead": 0,
    "behind": 0,
    "author_name": "Jackson Mafra",
    "author_email": "jackson.mafra@umain.com",
    "committer_date": "2026-05-16T11:43:46+02:00",
    "subject": "docs: add four-part article series in EN and PT-BR"
  },
  {
    "refname": "refs/remotes/origin/HEAD",
    "name": "origin",
    "oid": "93d47b34d9cbc6904161c1f9d444f52df783c830",
    "kind": "remote",
    "is_head": false,
    "upstream": null,
    "ahead": 0,
    "behind": 0,
    "author_name": "Jackson Mafra",
    "author_email": "jackson.mafra@umain.com",
    "committer_date": "2026-05-16T11:43:46+02:00",
    "subject": "docs: add four-part article series in EN and PT-BR"
  },
  {
    "refname": "refs/remotes/origin/main",
    "name": "origin/main",
    "oid": "93d47b34d9cbc6904161c1f9d444f52df783c830",
    "kind": "remote",
    "is_head": false,
    "upstream": null,
    "ahead": 0,
    "behind": 0,
    "author_name": "Jackson Mafra",
    "author_email": "jackson.mafra@umain.com",
    "committer_date": "2026-05-16T11:43:46+02:00",
    "subject": "docs: add four-part article series in EN and PT-BR"
  }
]
```


---

## `git json-blame` — per-line authorship

**Command**

```sh
cd PoisonStack
$ git json-blame README.md
```

**Output** (sliced for the demo)

```json
[
  {
    "line": 1,
    "content": "# PoisonStack",
    "commit": "0f4e2ebf40fb64b697acee5776bdb50755aac416",
    "abbreviated": "0f4e2eb",
    "orig_line": 1,
    "author": "Jackson Mafra",
    "author_email": "jackson.mafra@umain.com",
    "author_date": "2026-05-16T11:43:45+02:00",
    "committer": "Jackson Mafra",
    "committer_email": "jackson.mafra@umain.com",
    "committer_date": "2026-05-16T11:43:45+02:00",
    "summary": "docs: rewrite root README as a lean index",
    "filename": "README.md",
    "previous": "5a937fdef85c57399eae82c7a04bc17363f4db94 README.md",
    "boundary": false
  },
  {
    "line": 2,
    "content": "",
    "commit": "a0f3c9d75fe7098642770a3145f1cff64646c0a3",
    "abbreviated": "a0f3c9d",
    "orig_line": 2,
    "author": "Jackson Mafra",
    "author_email": "jackson.mafra@umain.com",
    "author_date": "2026-05-16T03:18:27+02:00",
    "committer": "Jackson Mafra",
    "committer_email": "jackson.mafra@umain.com",
    "committer_date": "2026-05-16T03:18:27+02:00",
    "summary": "docs: rebrand project as PoisonStack",
    "filename": "README.md",
    "previous": null,
    "boundary": false
  },
  {
    "line": 3,
    "content": "> A three-vector Android supply-chain attack PoC — malicious Gradle plugin,",
    "commit": "0f4e2ebf40fb64b697acee5776bdb50755aac416",
    "abbreviated": "0f4e2eb",
    "orig_line": 3,
    "author": "Jackson Mafra",
    "author_email": "jackson.mafra@umain.com",
    "author_date": "2026-05-16T11:43:45+02:00",
    "committer": "Jackson Mafra",
    "committer_email": "jackson.mafra@umain.com",
    "committer_date": "2026-05-16T11:43:45+02:00",
    "summary": "docs: rewrite root README as a lean index",
    "filename": "README.md",
    "previous": "5a937fdef85c57399eae82c7a04bc17363f4db94 README.md",
    "boundary": false
  }
]
```


---

## `git json-show` — one commit, fully expanded

**Command**

```sh
cd PoisonStack
$ git json-show 0f4e2eb
```

**Output** (sliced for the demo)

```json
{
  "commit": "0f4e2ebf40fb64b697acee5776bdb50755aac416",
  "abbreviated": "0f4e2eb",
  "parents": [
    "5a937fdef85c57399eae82c7a04bc17363f4db94"
  ],
  "author": {
    "name": "Jackson Mafra",
    "email": "jackson.mafra@umain.com",
    "date": "2026-05-16T11:43:45+02:00"
  },
  "stats": {
    "files_changed": 1,
    "insertions": 56,
    "deletions": 736
  },
  "files": [
    {
      "new_path": "README.md",
      "mode": "modified",
      "hunks": 1
    }
  ]
}
```


---

## `git json-range` — what changed between two refs

**Command**

```sh
cd PoisonStack
$ git json-range HEAD~5..HEAD
```

**Output** (sliced for the demo)

```json
{
  "base": "HEAD~5",
  "head": "HEAD",
  "merge_base": "35e4bfbe545d25407a066692b355964cc644607d",
  "stats": {
    "commits": 5,
    "files_changed": 30,
    "insertions": 3621,
    "deletions": 736
  },
  "files": [
    {
      "added": 56,
      "deleted": 736,
      "binary": false,
      "path": "README.md",
      "mode": "modified"
    },
    {
      "added": 15,
      "deleted": 0,
      "binary": false,
      "path": "androidlens-plugin/README.md",
      "mode": "added"
    },
    {
      "added": 33,
      "deleted": 0,
      "binary": false,
      "path": "articles/README.md",
      "mode": "added"
    },
    {
      "added": 219,
      "deleted": 0,
      "binary": false,
      "path": "articles/en/part-1-when-your-build-betrays-you.md",
      "mode": "added"
    },
    {
      "added": 238,
      "deleted": 0,
      "binary": false,
      "path": "articles/en/part-2-the-dependency-that-runs-code.md",
      "mode": "added"
    }
  ],
  "authors": [
    {
      "name": "Jackson Mafra",
      "email": "jackson.mafra@umain.com",
      "commits": 5
    }
  ]
}
```


---

## `git json-conflicts` — currently-unmerged files

**Command**

```sh
cd PoisonStack
$ git json-conflicts
```

**Output** (sliced for the demo)

```json
[]
```

Empty in this repo (nothing currently being merged). The shape would be:

```json
[
  {
    "path": "src/foo.ts",
    "conflict_style": "diff3",
    "conflicts": [
      {
        "start_line": 10, "end_line": 25,
        "ours_label": "HEAD", "theirs_label": "feature/bar",
        "ours":   ["..."], "base": ["..."], "theirs": ["..."],
        "context_before": ["..."], "context_after":  ["..."]
      }
    ]
  }
]
```

---

## `git recent` — recently touched files

**Command**

```sh
cd PoisonStack
$ git recent 20
```

**Output** (sliced for the demo)

```json
[
  {
    "path": "README.md",
    "touches": 2,
    "last_commit": "0f4e2eb",
    "last_date": "2026-05-16T11:43:45+02:00",
    "last_subject": "docs: rewrite root README as a lean index"
  },
  {
    "path": "speedbuild-plugin/build.gradle.kts",
    "touches": 1,
    "last_commit": "8621b80",
    "last_date": "2026-05-16T03:18:15+02:00",
    "last_subject": "build(speedbuild-plugin): bump Kotlin 2.3.20, AGP 9.1.1 and ASM 9.9.1"
  },
  {
    "path": "kryptokit/kryptokit-core/build.gradle.kts",
    "touches": 1,
    "last_commit": "0993c0a",
    "last_date": "2026-05-16T03:18:15+02:00",
    "last_subject": "build(kryptokit-core): bump SDK to 36, JVM target to 17 and core-ktx to 1.16.0"
  },
  {
    "path": "kryptokit/build.gradle.kts",
    "touches": 1,
    "last_commit": "5b1b49e",
    "last_date": "2026-05-16T03:18:15+02:00",
    "last_subject": "build(kryptokit): bump Kotlin Multiplatform 2.3.20 and AGP 9.1.1"
  },
  {
    "path": "androidlens-plugin/build.gradle.kts",
    "touches": 1,
    "last_commit": "f8e6934",
    "last_date": "2026-05-16T03:18:15+02:00",
    "last_subject": "build(androidlens-plugin): upgrade to Kotlin 2.3.20, IntelliJ plugin 1.17.4, target IDEA 2026.1"
  },
  {
    "path": "victim-app/app/build.gradle.kts",
    "touches": 1,
    "last_commit": "535406f",
    "last_date": "2026-05-16T03:18:15+02:00",
    "last_subject": "build(victim-app): bump toolchain to AGP 9.1.1, Kotlin 2.3.20, SDK 36"
  },
  {
    "path": "victim-app/build.gradle.kts",
    "touches": 1,
    "last_commit": "535406f",
    "last_date": "2026-05-16T03:18:15+02:00",
    "last_subject": "build(victim-app): bump toolchain to AGP 9.1.1, Kotlin 2.3.20, SDK 36"
  },
  {
    "path": "docs/01-overview.md",
    "touches": 1,
    "last_commit": "cfd8897",
    "last_date": "2026-05-16T11:43:45+02:00",
    "last_subject": "docs: add reference documentation under /docs"
  }
]
```


---

## `git stats` — repo summary

**Command**

```sh
cd PoisonStack
$ git stats
```

**Output** (sliced for the demo)

```json
{
  "head": {
    "branch": "main",
    "oid": "93d47b34d9cbc6904161c1f9d444f52df783c830",
    "subject": "docs: add four-part article series in EN and PT-BR"
  },
  "commits_total": 15,
  "branches": {
    "local": 1,
    "remote": 2
  },
  "authors": [
    {
      "name": "Jackson Mafra",
      "email": "jackson.mafra@umain.com",
      "commits": 15
    }
  ],
  "files_top": [
    {
      "path": "README.md",
      "touches": 2
    },
    {
      "path": "victim-app/settings.gradle.kts",
      "touches": 1
    },
    {
      "path": "victim-app/local.properties",
      "touches": 1
    },
    {
      "path": "victim-app/build.gradle.kts",
      "touches": 1
    },
    {
      "path": "victim-app/app/src/main/res/values/strings.xml",
      "touches": 1
    }
  ],
  "first_commit_date": "2026-05-16T03:18:15+02:00",
  "last_commit_date": "2026-05-16T11:43:46+02:00"
}
```


---

## `git tui-diff` — side-by-side terminal viewer

Renders a diff for human review in the terminal. The block below is the
uncolored output (real runs are ANSI-colored and auto-paged via `less`).

```text
### README.md  [modified]  +56/-736
@@ -1,764 +1,84 @@
  1 -# 🧪 PoisonStack                             │   1 +# PoisonStack                              
  2                                              │   2                                             
  3 -> **Educational PoC: a 3-vector Android su… │   3 +> A three-vector Android supply-chain atta…
                                                 │   4 +> malicious KMP library, malicious IDE plu…
  4                                              │   5                                             
  5 -> **⚠️ SECURITY RESEARCH - EDUCATIONAL USE… │   6 +PoisonStack ships three deliberately malic…
  6 ->                                           │   7 +the Android developer's "trust stack". Non…
  7 -> This repository demonstrates supply chai… │   8 +uses documented APIs in the way the docume…
  8 -> **DO NOT use maliciously. Created for se… │                                                 
  9 -                                            │                                                 
 10 -`PoisonStack` is the umbrella research pro… │                                                 
 11 -malicious components — each one a differen… │                                                 
 12 -"trust stack":                              │                                                 
 13                                              │   9                                             
 14  | Layer | Component | Disguise |            │  10  | Layer | Component | Disguise |           
 15  |-------|-----------|----------|            │  11  |-------|-----------|----------|           
 16 -| 🔌 Build system | `speedbuild-plugin` | "… │  12 +| Build system | [`speedbuild-plugin/`](sp…
 17 -| 📦 Dependency  | `kryptokit`         | "M… │  13 +| Dependency  | [`kryptokit/`](kryptokit) …
 18 -| 🎨 IDE          | `androidlens-plugin`| "… │  14 +| IDE         | [`androidlens-plugin/`](an…
 19 -                                            │                                                 
 20 -Three poisoned layers, one compromised sta… │                                                 
 21 -                                            │                                                 
 22 ----                                         │                                                 
 23 -                                            │                                                 
 24 -## 📋 Project Overview                       │                                                 
 25 -                                            │                                                 
 26 -This proof-of-concept demonstrates **three… │                                                 
 27 -                                            │                                                 
 28 -1. **🔌 SpeedBuild** - Malicious Gradle Plu… │                                                 
 29 -2. **🔐 KryptoKit** - Malicious Kotlin Mult… │                                                 
 30 -3. **🎨 AndroidLens** - Malicious IDE Plugi… │                                                 
 31 -                                            │                                                 
 32 -### Combined Attack Surface                 │                                                 
 33 -                                            │                                                 
 34 -When a developer uses **all three** malici… │                                                 
 35 -                                            │                                                 
 36 -```                                         │                                                 
 37 -Build-Time Attack    +    Runtime Attack  … │                                                 
```

---

## `git visual-diff` — side-by-side HTML viewer

```sh
cd PoisonStack
$ git visual-diff HEAD~1..HEAD          # opens in your browser
$ git visual-diff --print HEAD~1..HEAD  # write the path, don't open
```

The viewer is a single self-contained HTML file with two-column rendering,
highlight.js syntax highlighting, and prev/next file navigation. Read-only.

---

## See also

- [`AGENTS.md`](../AGENTS.md) — TypeScript-style schema for every JSON-emitting command
- [`CHANGELOG.md`](../CHANGELOG.md) — release notes
- [`README.md`](../README.md) — install, usage, security model, agent discovery
