# Increment 9 — Unscoped protected folders

**Status:** Draft (2026-11-01), split from increment 7.

## Goal

Stop TCC from silently shrinking the results of an unscoped `search` or `spotlight_query`. Without access to `~/Downloads`, `~/Documents` or `~/Desktop`, Spotlight drops their files with no error.

## Contract

- An unscoped `search` or `spotlight_query` counts as a scope containing `~/Downloads`, `~/Documents` and `~/Desktop`, and carries increment 8's `unreadableFolders` for each one oxus cannot read.

## Out of scope

- Protected locations other than `~/Downloads`, `~/Documents` and `~/Desktop`.

## Design

See increment 7 for who TCC judges and the access prompt, and increment 8 for the warning field and probe order.

## Open decisions

None.

## Decisions

- **Unscoped searches** (2026-11-01): treated as a scope containing all three protected folders, for both `search` and `spotlight_query`, which share the increment 4 output. Confirmed for `search` on 2026-11-01 from iTerm and Claude Desktop: the unscoped `search` returned no paths, with no error and no prompt; `spotlight_query` was not checked.

## Test list

`docs/tests/increment-9-test-list.txt`

## Risks

- **`spotlight_query` not checked.** It runs the same Spotlight query path as `search`, so it is expected to lose the same results.
- **Up to three prompts on a first call.** With no decision on record, the first unscoped call probes all three protected folders, which may bring up three prompts in a row, each blocking the call.
