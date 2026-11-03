# Increment 11 — Truncated results

**Status:** Planned

## Goal

Stop `limit` from silently shortening a result. Today 25 paths can be every match or the first 25 of thousands, and an agent cannot tell which, the same quiet short answer `unreadableFolders` flags for the privacy folders.

## Contract

- A `spotlight_query` or `search` whose matches exceed `limit` returns `"truncated": true` next to `paths`, in structured content and in the JSON text block. `paths` still holds `limit` paths.
- When every match is returned, including when the matches equal `limit` exactly, the result has no `truncated` key, as with `unreadableFolders`.
- `truncated` and `unreadableFolders` are independent: a result can carry both.
- The output schema of both tools advertises `truncated` as an optional boolean, described as more matches existing than `paths` holds, so raise `limit` or narrow the search.
- Error results are unchanged.
- `limit` keeps its default of 25, its maximum of 100 and its error messages.

## Out of scope

- A total match count.
- Paging through results.
- Any change to Spotlight's result order.

## Design

- Spotlight stays capped, one result above `limit`. A result beyond `limit` means the matches were cut off; it is dropped before the response is built.
- The field is added to `OxusResponse`, which both tools share.
- `limit + 1` can reach 101, above `Limit.maximum`.
- Adding an optional field is not a breaking change, so this ships as a patch release under `docs/releasing.md`.

## Manual check

In Claude Desktop, run a `search` that matches more than 25 files and see `truncated: true`, then raise `limit` above the match count of a narrower search and see no `truncated` key.

## Open decisions

- How the `Spotlight` port reports that matches were cut off, given it returns `[String]` today.
- Which side computes `limit + 1`: the server, which needs a value above `Limit.maximum`, or `CoreServicesSpotlight`.

## Decisions

- **Capped at `limit + 1`, not filtered in code** (2026-11-03): measured with `MDQuery` on a Mac with about 234,000 indexed items, in fresh processes, twice each. `kMDItemFSName == "*a*"`, 130,352 matches: 0.03 s capped, 2.9 s uncapped. `kMDItemContentTypeTree == "public.item"`, 234,462 matches: about 5 s either way. `kMDItemFSName == "Finder.app"`: about 1 ms either way. Memory is no argument, at 8 MB capped and 22 MB uncapped. The cost of filtering in code is about 100 times the latency on a broad name search, which is the common `search`, and it would only pay for a total count this increment does not return.
- **No key instead of `false`** (2026-11-03): matches `unreadableFolders`, which appears only when there is something to report.

## Test list

[`011-truncated-results.test-list.txt`](011-truncated-results.test-list.txt)

## Risks

- **Items without a path.** The adapter drops any item with no `kMDItemPath`, so such an item could make a result shorter than `limit`, or use up the extra result and hide a cut-off. None appeared in the first 5,000 results of the two broad queries above, so this is unproven rather than ruled out.
- **Broad type queries stay slow.** A cap does not help `kMDItemContentTypeTree == "public.item"`; it takes about 5 s with or without this increment.
