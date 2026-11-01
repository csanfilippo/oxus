# Increment 7 — Protected folders

**Status:** Draft (2026-10-25)

## Goal

Stop macOS privacy protection (TCC) from silently shrinking search results, and tell the user exactly what to fix. Without access to `~/Downloads`, `~/Desktop` or `~/Documents`, Spotlight drops their files with no error, so the model reports "no files" as fact. Increment 6 turns a denied scope folder into a "cannot read" error carrying the reason macOS gives; this increment makes that error say what to grant, and covers the cases increment 6 leaves silent.

## Contract

- A scope folder denied by TCC and one denied by file permissions are separate errors, each naming what to fix. Replaces increment 6's single "cannot read" error.
  - TCC: the setting to change (System Settings › Privacy & Security › Files and Folders › the folder), granted to `oxus` if it is listed there, otherwise to the app that launched oxus.
  - File permissions: the missing read permission.
- A successful `search` or `spotlight_query` whose scope contains `~/Downloads`, `~/Documents` or `~/Desktop` that oxus cannot read carries, next to `paths`, an optional `unreadableFolders` array with one `{"path": ..., "fix": ...}` object per such folder, `fix` being the same TCC fix as the error's. The folders are probed before the Spotlight query runs. An unscoped call counts as a scope containing all three. Extends the increment 4 output schema; a call with no unreadable protected folder returns the increment 4 output unchanged.

## Out of scope

- Protected locations other than `~/Downloads`, `~/Documents` and `~/Desktop`, such as iCloud Drive, removable and network volumes, and other apps' data.
- Finding the responsible app at runtime: the TCC fix names both candidates instead.
- Keeping a grant across rebuilds, e.g. signing oxus with a stable identity.

## Design

- **Telling denials apart:** the adapter tells the two denials apart by the underlying POSIX error: `EPERM` for TCC, `EACCES` for file permissions. `EACCES` was checked with a `chmod 000` folder on 2026-10-25. `EPERM` was checked on 2026-11-01: with `~/Downloads` denied, oxus reported "Operation not permitted", the `strerror` text of the underlying POSIX code, from both iTerm and Claude Desktop. The Cocoa error code was not observed; the adapter does not depend on it.
- **Who TCC judges:** it depends on the host, observed on 2026-11-01. Launched from iTerm, oxus is judged as iTerm: it is denied exactly when iTerm is, and no prompt names oxus. Launched from Claude Desktop, oxus is judged as itself: the prompt reads "oxus would like to access files in the Downloads folder", and Claude's own Files and Folders setting plays no part.
- **Access prompt:** when the judged app has no decision on record, the first listing of a protected folder triggers the macOS access prompt, observed with oxus from Claude Desktop on 2026-11-01. The listing, and so the tool call, blocks until the user answers. Once a decision is on record, no prompt appears again; `tccutil reset SystemPolicyDownloadsFolder` (and the `Documents` and `Desktop` equivalents) clears it for every app.

## Open decisions

None.

## Decisions

- **Which app the error names** (2026-11-01): both candidates, `oxus` if listed in Files and Folders, otherwise the app that launched it. The app TCC judges varies with the host (see Design: Who TCC judges); naming both is correct in both observed cases without a private API, at the cost of precision.
- **Protected subfolders inside a readable scope** (2026-11-01): warn next to `paths`. Confirmed with oxus on 2026-11-01 from iTerm and Claude Desktop: a `search` for `documento2` scoped to `~` returned no paths, with no error and no prompt, while the file sat in a denied `~/Downloads`. Detection checks only the three known protected folders inside the scope.
- **Unscoped searches** (2026-11-01): treated as a scope containing all three protected folders, for both `search` and `spotlight_query`, which share the increment 4 output. Confirmed for `search` on 2026-11-01 from iTerm and Claude Desktop: the unscoped `search` returned no paths, with no error and no prompt; `spotlight_query` was not checked.
- **Warning field** (2026-11-01): `unreadableFolders`, an array of `{path, fix}` objects. The path can be checked without matching prose, and "unreadable" is the term `FolderError` already uses; the fix text repeats per folder.
- **Probe order** (2026-11-01): before the Spotlight query, like the scope check. Probing after has a silent loss: a grant given at the prompt makes the probe succeed with no warning, though the query ran without access.

## Test list

`docs/tests/increment-7-test-list.txt`

## Risks

- **Spotlight filters silently without access.** Checked on 2026-10-25 with the same PDF query from the terminal, which has access, and from a `launchd` job without the terminal's grants: a scope of `~/Downloads` returned 121 paths from the terminal and 0 from the job, a scope of `~` returned 949 and 15, and listing `~/Downloads` from the job failed with "Operation not permitted".
- **TCC judges the binary when there is no host app.** On 2026-10-25 a `launchd` job running `/bin/sh` was denied `~/Downloads` with no prompt, but a `launchd` job running an ad-hoc-signed Swift probe triggered an access prompt and, once allowed, listed it.
- **Tests cannot revoke TCC access.** A folder with no read permission covers the file-permission case only, so the TCC case is checked by hand.
- **A slow answer to the prompt may outlast the client's timeout.** The tool call blocks while the prompt is open. On 2026-11-01 the prompt stayed open about 60 seconds and Claude Desktop retried the call; whether the first call timed out was not seen. Not verified.
- **A rebuild may drop the grant.** TCC identifies an ad-hoc-signed binary by its code, and the debug build's identifier carries a hash (`oxus-5555…`), so each rebuild or update may prompt again. Not verified.
- **Up to three prompts on a first call.** With no decision on record, the first unscoped or `~`-scoped call probes all three protected folders, which may bring up three prompts in a row, each blocking the call.
- **A grant at the prompt may not reach the same call's results.** Probing first lets the user grant access before the query runs, but whether Spotlight then returns that folder's files in the same process was not checked.
- **An unexplained Documents prompt.** Before the 2026-11-01 reset, Claude Desktop once showed "oxus would like to access files in the Documents folder" during the checks; it did not recur after the reset, and its trigger is unknown.
