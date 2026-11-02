# Increment 8 — Protected subfolders

**Status:** Done (2026-11-01)

## Goal

Stop TCC from silently shrinking the results of a `search` scoped to a readable folder. Without access to `~/Downloads`, `~/Documents` or `~/Desktop`, a scope such as `~` lists fine but Spotlight drops the files inside them with no error, so the model reports "no files" as fact.

## Contract

- A successful `search` whose scope contains `~/Downloads`, `~/Documents` or `~/Desktop` that oxus cannot read carries, next to `paths`, an optional `unreadableFolders` array with one `{"path": ..., "fix": ...}` object per such folder, `fix` being the TCC fix of increment 7's error. The folders are probed before the Spotlight query runs.
- Extends the increment 4 output schema; a call with no unreadable protected folder returns the increment 4 output unchanged.

## Out of scope

- Unscoped `search` and `spotlight_query`: increment 9.
- Protected locations other than `~/Downloads`, `~/Documents` and `~/Desktop`.

## Design

See increment 7 for who TCC judges and the access prompt.

## Manual check

On 2026-11-01, Claude Desktop's `search` for `documento2` scoped to `~`, with the file in `~/Downloads`, returned no paths and no error, and an `unreadableFolders` entry for each of `/Users/feanor/Downloads`, `/Users/feanor/Documents` and `/Users/feanor/Desktop`, in that order. Each `fix` named its Files and Folders setting, for oxus if it is listed there, otherwise the app that launched oxus.

## Open decisions

None.

## Decisions

- **Protected subfolders inside a readable scope** (2026-11-01): warn next to `paths`. Confirmed with oxus on 2026-11-01 from iTerm and Claude Desktop: a `search` for `documento2` scoped to `~` returned no paths, with no error and no prompt, while the file sat in a denied `~/Downloads`. Detection checks only the three known protected folders inside the scope.
- **Warning field** (2026-11-01): `unreadableFolders`, an array of `{path, fix}` objects. The path can be checked without matching prose, and "unreadable" is the term `FolderError` already uses; the fix text repeats per folder.
- **Probe order** (2026-11-01): before the Spotlight query, like the scope check. Probing after has a silent loss: a grant given at the prompt makes the probe succeed with no warning, though the query ran without access.
- **Which failures warn** (2026-11-01): only a TCC denial, the one case where Spotlight's silent filtering was observed; a missing folder, a file-permission denial or another read failure adds no entry.
- **Telling the model** (2026-11-01): the `unreadableFolders` description in the output schema says those folders' files are missing from `paths`; the `search` description is unchanged.
- **End-to-end coverage** (2026-11-01): an acceptance test on a temporary home with readable protected folders, plus a manual check with Downloads denied, since tests cannot make TCC deny a folder.

## Test list

[`008-protected-subfolders.test-list.txt`](008-protected-subfolders.test-list.txt)

## Risks

- **Spotlight filters silently without access.** Checked on 2026-10-25 with the same PDF query from the terminal, which has access, and from a `launchd` job without the terminal's grants: a scope of `~/Downloads` returned 121 paths from the terminal and 0 from the job, a scope of `~` returned 949 and 15, and listing `~/Downloads` from the job failed with "Operation not permitted".
- **Up to three prompts on a first call.** With no decision on record, the first `~`-scoped call probes all three protected folders, which may bring up three prompts in a row, each blocking the call.
- **A grant at the prompt may not reach the same call's results.** Probing first lets the user grant access before the query runs, but whether Spotlight then returns that folder's files in the same process was not checked.
