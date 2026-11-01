# Increment 7 — Protected folders

**Status:** Draft (2026-10-25)

## Goal

Tell the user exactly what to fix when macOS privacy protection (TCC) or file permissions deny the scope folder of a `search`. Increment 6 turns a denied scope folder into a "cannot read" error carrying the reason macOS gives; this increment makes that error say what to grant.

## Contract

- A scope folder denied by TCC and one denied by file permissions are separate errors, each naming what to fix. Replaces increment 6's single "cannot read" error.
  - TCC: the setting to change (System Settings › Privacy & Security › Files and Folders › the folder), granted to `oxus` if it is listed there, otherwise to the app that launched oxus. The folder is the protected folder containing the scope, so a scope inside `~/Downloads` names Downloads. A scope outside `~/Downloads`, `~/Documents` and `~/Desktop` gets a generic fix pointing to Privacy & Security, with no folder setting.
  - File permissions: the missing read permission.
- Any other read failure keeps increment 6's error: the path and the reason macOS gives.

## Out of scope

- Protected folders inside a readable scope losing results silently: increment 8.
- Unscoped `search` and `spotlight_query` losing results silently: increment 9.
- Naming the setting for protected locations other than `~/Downloads`, `~/Documents` and `~/Desktop`, such as iCloud Drive, removable and network volumes, and other apps' data: they get the generic fix.
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
- **Split** (2026-11-01): protected folders inside a readable scope and unscoped calls move to increments 8 and 9.
- **Nested scope** (2026-11-01): a scope inside a protected folder names that folder's setting, the one the user has to change.
- **Other `EPERM`** (2026-11-01): a generic Privacy & Security fix, so the user still learns it is TCC.
- **Other read failures** (2026-11-01): increment 6's error, unchanged.
- **Testing `EPERM`** (2026-11-01): an adapter test on a constructed Cocoa error wrapping POSIX `EPERM`, plus a manual check with a denied folder.

## Test list

`docs/tests/increment-7-test-list.txt`

## Risks

- **TCC judges the binary when there is no host app.** On 2026-10-25 a `launchd` job running `/bin/sh` was denied `~/Downloads` with no prompt, but a `launchd` job running an ad-hoc-signed Swift probe triggered an access prompt and, once allowed, listed it.
- **Tests cannot revoke TCC access.** A folder with no read permission covers the file-permission case only, so the TCC case is checked by hand.
- **A slow answer to the prompt may outlast the client's timeout.** The tool call blocks while the prompt is open. On 2026-11-01 the prompt stayed open about 60 seconds and Claude Desktop retried the call; whether the first call timed out was not seen. Not verified.
- **A rebuild may drop the grant.** TCC identifies an ad-hoc-signed binary by its code, and the debug build's identifier carries a hash (`oxus-5555…`), so each rebuild or update may prompt again. Not verified.
- **An unexplained Documents prompt.** Before the 2026-11-01 reset, Claude Desktop once showed "oxus would like to access files in the Documents folder" during the checks; it did not recur after the reset, and its trigger is unknown.
