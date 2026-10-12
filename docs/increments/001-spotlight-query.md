# Increment 1 — `spotlight_query`

**Status:** Defined

## Goal

Replace `hello` with a `spotlight_query` tool that runs a raw Spotlight query and returns the paths of matching files. The thinnest slice that wires the MCP contract, a Spotlight port and its real adapter end to end, with no query interpretation.

## Contract

- Input: `query` (string, required, Spotlight query syntax, e.g. `kMDItemFSName == "*.pdf"c`), `limit` (integer, optional, default 25, capped at 100).
- Output: one text content block per matching file path, in Spotlight's order.
- Empty or blank `query`, malformed `query`, or `limit < 1` returns a result with `isError: true` and a message the client can act on.
- Unknown tool names still throw `invalidParams`.
- `hello` is removed.
- The tool description teaches the query syntax with examples.

## Out of scope

Free-text search (increment 2), folder scopes, metadata in results, structured content, pagination, live queries.

## Design

- **Port:** a `Spotlight` protocol in `OxusServer`, injected through `makeOxusServer(spotlight:)`, with an explicit invalid-query outcome. Protocol tests keep driving the MCP `Client` against a fake, independent of the machine's index.
- **Adapter:** `CoreServicesSpotlight` using `MDQueryCreate` + `MDQueryExecute(…, kMDQuerySynchronous)`, with `MDQuerySetMaxCount` for the limit. `MDQueryCreate` returning `NULL` signals a malformed query. Preferred over `NSMetadataQuery` (run-loop and notification driven, poor fit for strict concurrency) and over spawning `mdfind` (process management and output parsing for no gain).
- **Adapter tests:** a few tests against real Spotlight querying always-indexed system files (e.g. `Finder.app`), tagged so the default `swift test` run stays fast. Temporary directories are not indexed, and polling for a freshly indexed file would make tests timing-dependent.

## Decisions

- **Raw query language first:** passing the query through untouched keeps this increment about wiring. Free text follows in increment 2.
- **Tool named after its grammar:** `spotlight_query` keeps one meaning forever, so free text arrives as a separate tool rather than a breaking change or mutually exclusive parameters.
- **No matches is success with empty content:** every content block is a path, so the result has a single meaning.
- **Limit above the cap is clamped,** not rejected: a large limit means "as many as possible".
- **No truncation signal yet:** it belongs with pagination.

## Test list

`docs/tests/increment-1-test-list.txt`

## Risks

- Clients will often write malformed queries; the error message and tool description carry the burden of recovery.
- TCC may silently filter results in protected locations unless the host app has Full Disk Access. Document once observed.
