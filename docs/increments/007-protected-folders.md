# Increment 7 — Protected folders

**Status:** Draft (2026-10-25)

## Goal

Stop macOS privacy protection (TCC) from silently shrinking search results, and tell the user exactly what to fix. Without access to `~/Downloads`, `~/Desktop` or `~/Documents`, Spotlight drops their files with no error, so the model reports "no files" as fact. Increment 6 turns a denied scope folder into a "cannot read" error carrying the reason macOS gives; this increment makes that error say what to grant, and covers the cases increment 6 leaves silent.

## Contract

- A scope folder denied by TCC and one denied by file permissions are separate errors, each naming what to fix: the permission to grant, and to which app, for TCC; the missing read permission for file permissions. Replaces increment 6's single "cannot read" error.

## Out of scope

To be decided once the open decisions below are settled.

## Design

- **Telling denials apart:** both denials are expected to arrive as Cocoa error 257 (`fileReadNoPermission`), so the adapter tells them apart by the underlying POSIX error: `EPERM` for TCC, `EACCES` for file permissions. `EACCES` was checked with a `chmod 000` folder on 2026-10-25; for TCC, only `ls` printing "Operation not permitted" has been seen, not the Foundation error.
- **Access prompt:** the first listing of a protected folder can trigger the macOS access prompt, which is what the user needs to fix it (observed with a Swift probe on 2026-10-25, not yet with oxus).

## Open decisions

- **Who TCC judges:** the host app that launches oxus, or oxus itself? This decides which app the error tells the user to grant. A `launchd` job has no host app, so TCC judged its binary; an MCP host normally makes itself responsible for the processes it launches, but an app can launch a child that is responsible for itself. Check by hand: turn off Downloads for the terminal app in System Settings › Privacy & Security › Files and Folders, run the server with a `search` scoped to `~/Downloads`, see which app the prompt names or the denial applies to, then turn it back on; repeat from Claude Desktop.
- **Protected subfolders inside a readable scope:** a scope such as `~` lists fine but silently loses results from `~/Downloads`, `~/Desktop` or `~/Documents` when the host has no access to them. Warn alongside the paths, e.g. an optional field next to `paths` naming the unreadable subfolders and the permission to grant, or accept partial results? A warning extends the increment 4 output schema, and detection can only check known protected locations inside the scope.
- **Unscoped searches:** an unscoped `search` or `spotlight_query` from a host without access probably loses the same results (not checked). Confirm, then decide whether this increment addresses it.

## Test list

`docs/tests/increment-7-test-list.txt`

## Risks

- **Spotlight filters silently without access.** Checked on 2026-10-25 with the same PDF query from the terminal, which has access, and from a `launchd` job without the terminal's grants: a scope of `~/Downloads` returned 121 paths from the terminal and 0 from the job, a scope of `~` returned 949 and 15, and listing `~/Downloads` from the job failed with "Operation not permitted".
- **TCC judges the binary when there is no host app.** On 2026-10-25 a `launchd` job running `/bin/sh` was denied `~/Downloads` with no prompt, but a `launchd` job running an ad-hoc-signed Swift probe triggered an access prompt and, once allowed, listed it.
- **Tests cannot revoke TCC access.** A folder with no read permission covers the file-permission case only, so the TCC case is checked by hand.
