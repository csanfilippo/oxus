# Increment 13 — Explicit truncated

**Status:** Done (2026-11-06), not yet released

## Goal

Make every successful result say whether it is complete. Since 0.3.0 a complete result has no `truncated` key, so a model that never sees the output schema has to guess what a missing key means when it gets exactly 25 paths.

## Contract

- A successful `spotlight_query` or `search` always returns `truncated` next to `paths`, in structured content and in the JSON text block.
- `truncated` is `true` when matches exceed `limit`, and `false` otherwise, including when the matches equal `limit` exactly.
- `unreadableFolders` is unchanged: it still appears only when there is something to report.
- The output schema of both tools lists `truncated` as a required boolean, and `required` becomes `paths` and `truncated`.
- The `truncated` description no longer says the key can be absent.
- The `limit` argument's description, shared by both tools, says `truncated` is true when a result is cut off.
- Error results are unchanged: no structured content.

## Out of scope

- A total match count.
- Paging through results.
- Any change to how `CoreServicesSpotlight` finds a cut-off.
- Any change to `unreadableFolders`.

## Design

- `OxusResponse.truncated` becomes a plain `Bool`, which drops the `? true : nil` in its initialiser.
- The `Spotlight` port and `SpotlightMatches` are unchanged.
- A client written against 0.3.0 may test whether the key exists, and would read `"truncated": false` as a cut-off. That changes a tool's results, so this ships as a minor release, 0.4.0, under `docs/releasing.md`.

## Manual check

Point a client at a release build of this increment. Run a `search` that matches more than 25 files and see `truncated: true`, then raise `limit` above the match count of a narrower search and see `truncated: false`.

Run and confirmed by the user on 2026-11-06.

## Open decisions

None.

## Decisions

- **Always present, not only when true** (2026-11-06): supersedes increment 12's "No key instead of `false`". A flag always has a value, unlike `unreadableFolders`, where absence naturally means nothing to report. The result stops relying on a client knowing what a missing key means, and some clients do not show output schemas to the model. The cost is that every exact `structuredContent` assertion in the tests names `truncated`, and the response no longer follows one rule of reporting only what is wrong.
- **Required in the output schema** (2026-11-06): the schema describes what every result carries.

## Test list

[`013-explicit-truncated.test-list.txt`](013-explicit-truncated.test-list.txt)

## Risks

- **Clients written against 0.3.0.** A client that tests for the key instead of its value treats every complete result as cut off. The changelog entry for 0.4.0 has to say so.
