# Increment 12 — Truncated results

**Status:** Planned

## Goal

Stop `limit` from silently shortening a result. Today 25 paths can be every match or the first 25 of thousands, and an agent cannot tell which, the same quiet short answer `unreadableFolders` flags for the privacy folders.

## Contract

- A `spotlight_query` or `search` whose matches exceed `limit` returns `"truncated": true` next to `paths`, in structured content and in the JSON text block. `paths` still holds `limit` paths.
- When every match is returned, including when the matches equal `limit` exactly, the result has no `truncated` key, as with `unreadableFolders`.
- `truncated` and `unreadableFolders` are independent: a result can carry both.
- The output schema of both tools advertises `truncated` as an optional boolean, described as more matches existing than `paths` holds, so raise `limit` or narrow the search.
- The `limit` argument's description, shared by both tools, says a cut-off result carries `truncated`.
- Error results are unchanged.
- `limit` keeps its default of 25, its maximum of 100 and its error messages.

## Out of scope

- A total match count.
- Paging through results.
- Any change to Spotlight's result order.

## Design

- `CoreServicesSpotlight` caps `MDQuery` at one result above `limit`. A result beyond `limit` means more matches exist; it drops that result and tells the server through the `Spotlight` port.
- The field is added to `OxusResponse`, which both tools share.
- `Limit` is unchanged: `limit + 1` stays inside the adapter, so a value of 101 never has to pass through it.
- Adding an optional field is not a breaking change, so this ships as a patch release under `docs/releasing.md`.

## Manual check

In Claude Desktop, run a `search` that matches more than 25 files and see `truncated: true`, then raise `limit` above the match count of a narrower search and see no `truncated` key.

## Open decisions

None.

## Decisions

- **Capped at `limit + 1`, not filtered in code** (2026-11-03): measured with `MDQuery` on a Mac with about 234,000 indexed items, in fresh processes, twice each. `kMDItemFSName == "*a*"`, 130,352 matches: 0.03 s capped, 2.9 s uncapped. `kMDItemContentTypeTree == "public.item"`, 234,462 matches: about 5 s either way. `kMDItemFSName == "Finder.app"`: about 1 ms either way. Memory is no argument, at 8 MB capped and 22 MB uncapped. The cost of filtering in code is about 100 times the latency on a broad name search, which is the common `search`, and it would only pay for a total count this increment does not return.
- **The adapter finds the cut-off** (2026-11-03): `CoreServicesSpotlight` over-fetches and the port reports the fact that more matches exist, instead of the server asking for `limit + 1`. How the cut-off is found is a detail of driving Spotlight, the server still decides what it means for a client, and `Limit` keeps its meaning. The cost is a changed port, a changed `SpySpotlight` and adapter tests for the new behaviour.
- **`SpotlightMatches`** (2026-11-03): the `Spotlight` port returns a struct, declared in `OxusServer` next to the port, in place of `[String]`. It holds the paths and whether more matches exist. An enum with one case per outcome was rejected: both cases would carry the same paths, so the variation is a flag, and every consumer would unwrap a case to reach them.
- **`limit` also explains `truncated`** (2026-11-03): some MCP clients do not show output schemas to the model, while the argument description always reaches it.
- **No key instead of `false`** (2026-11-03): matches `unreadableFolders`, which appears only when there is something to report.

## Test list

[`012-truncated-results.test-list.txt`](012-truncated-results.test-list.txt)

## Risks

- **Items without a path.** The adapter drops any item with no `kMDItemPath`, so such an item could make a result shorter than `limit`. Comparing Spotlight's raw result count with `limit` keeps it from hiding a cut-off. None appeared in the first 5,000 results of the two broad queries above.
- **Broad type queries stay slow.** A cap does not help `kMDItemContentTypeTree == "public.item"`; it takes about 5 s with or without this increment.
