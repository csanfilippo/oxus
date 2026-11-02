# Increment 9 — Unscoped protected folders

**Status:** Done (2026-11-01)

## Goal

Stop TCC from silently shrinking the results of an unscoped `search` or `spotlight_query`. Without access to `~/Downloads`, `~/Documents` or `~/Desktop`, Spotlight drops their files with no error.

## Contract

- An unscoped `search` or `spotlight_query` counts as a scope containing `~/Downloads`, `~/Documents` and `~/Desktop`, and carries increment 8's `unreadableFolders` for each one oxus cannot read.

## Out of scope

- Protected locations other than `~/Downloads`, `~/Documents` and `~/Desktop`.

## Design

See increment 7 for who TCC judges and the access prompt, and increment 8 for the warning field and probe order.

## Manual check

On 2026-11-01, with `documento2` in a denied `~/Downloads`, Claude Desktop's unscoped `search` for `documento2` and its `spotlight_query` for `kMDItemFSName == "*documento2*"c` each returned no paths and no error, and an `unreadableFolders` entry for each of `/Users/feanor/Downloads`, `/Users/feanor/Documents` and `/Users/feanor/Desktop`, in that order, each `fix` naming its Files and Folders setting. The empty `spotlight_query` result confirms it loses the denied folder's files like `search`.

## Open decisions

None.

## Decisions

- **Unscoped searches** (2026-11-01): treated as a scope containing all three protected folders, for both `search` and `spotlight_query`, which share the increment 4 output. Confirmed for `search` on 2026-11-01 from iTerm and Claude Desktop: the unscoped `search` returned no paths, with no error and no prompt; `spotlight_query` was not checked.
- **Acceptance test home** (2026-11-01): every acceptance test starts the server with a temporary home whose protected folders are readable. Unscoped calls now probe the home's protected folders, and the real home would make runs prompt and depend on the machine's privacy settings.
- **Checking `spotlight_query`** (2026-11-01): the manual check covers both tools, which also settles the risk that `spotlight_query` was never seen losing results.

## Test list

[`009-unscoped-protected-folders.test-list.txt`](009-unscoped-protected-folders.test-list.txt)

## Risks

- **`spotlight_query` not checked.** Settled by the manual check: it loses the denied folder's files like `search`.
- **Up to three prompts on a first call.** With no decision on record, the first unscoped call probes all three protected folders, which may bring up three prompts in a row, each blocking the call.
