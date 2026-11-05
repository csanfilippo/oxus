# Increment 12 — Truncated results

**Status:** Done (2026-11-06), not yet released

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

- `CoreServicesSpotlight` runs `MDQuery` without a cap and keeps the first `limit` results. A raw result count above `limit` means more matches exist, and it tells the server through the `Spotlight` port.
- The field is added to `OxusResponse`, which both tools share.
- `Limit` is unchanged.
- Adding an optional field is not a breaking change, so this ships as a patch release under `docs/releasing.md`.

## Manual check

In Claude Desktop, run a `search` that matches more than 25 files and see `truncated: true`, then raise `limit` above the match count of a narrower search and see no `truncated` key.

Run on 2026-11-06 in Claude Code rather than Claude Desktop, through a real MCP connection to a release build of this branch, and accepted as the manual check. `search` for `photo` at the default limit returned 25 paths and `truncated: true`, where the previous build returned 2 paths and no key. `search` for `invoice` with a `limit` of 100 returned 7 paths and no `truncated` key.

## Open decisions

None.

## Decisions

- **No cap, filtered in code** (2026-11-06): `MDQuerySetMaxCount` gives wrong answers on `kMDItemDisplayName`, the attribute `search` matches, so "Capped at `limit + 1`" below is reversed. Measured with raw `MDQuery` on the same Mac, cap 101 against uncapped: `photo` 2 of 479, `.app` 3 of 1,079, `finde` 71 of 87, `apple` 76 of 5,699, `swift` 95 of 6,629, and `kMDItemDisplayName == "*photo*"` returns 30 of 60, a cap above every match still changing the result. The shortfall varies between runs. `MDQueryIsGatheringComplete` is already true at the short count, and a run loop changes nothing. Released 0.2.1 returns the same short `paths`, so this also fixes that. Retrying without the cap whenever the capped query stayed under it was rejected: two paths through one operation, only to keep one-letter searches fast. `kMDItemFSName` was rejected too: increment 2 chose the display name on purpose, and `spotlight_query` would stay exposed.
- **Capped at `limit + 1`, not filtered in code** (2026-11-03, reversed 2026-11-06): measured with `MDQuery` on a Mac with about 234,000 indexed items, in fresh processes, twice each. `kMDItemFSName == "*a*"`, 130,352 matches: 0.03 s capped, 2.9 s uncapped. `kMDItemContentTypeTree == "public.item"`, 234,462 matches: about 5 s either way. `kMDItemFSName == "Finder.app"`: about 1 ms either way. Memory is no argument, at 8 MB capped and 22 MB uncapped. The cost of filtering in code is about 100 times the latency on a broad name search, which is the common `search`, and it would only pay for a total count this increment does not return.
- **The adapter finds the cut-off** (2026-11-03): `CoreServicesSpotlight` compares its result count with `limit` and the port reports the fact that more matches exist, instead of the server working it out. How the cut-off is found is a detail of driving Spotlight, the server still decides what it means for a client, and `Limit` keeps its meaning. The cost is a changed port, a changed `SpySpotlight` and adapter tests for the new behaviour.
- **`SpotlightMatches`** (2026-11-03): the `Spotlight` port returns a struct, declared in `OxusServer` next to the port, in place of `[String]`. It holds the paths and whether more matches exist. An enum with one case per outcome was rejected: both cases would carry the same paths, so the variation is a flag, and every consumer would unwrap a case to reach them.
- **`limit` also explains `truncated`** (2026-11-03): some MCP clients do not show output schemas to the model, while the argument description always reaches it.
- **No key instead of `false`** (2026-11-03): matches `unreadableFolders`, which appears only when there is something to report.

## Test list

[`012-truncated-results.test-list.txt`](012-truncated-results.test-list.txt)

## Risks

- **Items without a path.** The adapter drops any item with no `kMDItemPath`, so such an item could make a result shorter than `limit`. Comparing Spotlight's raw result count with `limit` keeps it from hiding a cut-off. None appeared in the first 5,000 results of the two broad queries above.
- **Broad searches are slow.** Without a cap, a search pays for every match: `kMDItemFSName == "*a*"` took 2.9 s in a fresh process, one-letter `search` names took 1.3 to 5.8 s, and `kMDItemContentTypeTree == "public.item"` takes about 5 s. Typical names take 10 to 40 ms. Queries run one at a time, so a slow one also delays any call waiting behind it.
