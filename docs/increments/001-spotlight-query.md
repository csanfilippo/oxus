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
- **Adapter tests:** a few slow tests against real Spotlight using a uniquely named temporary file, tagged so the default `swift test` run stays fast.

## Decisions

- **Raw query language first:** passing the query through untouched keeps this increment about wiring. Free text follows in increment 2.
- **Tool named after its grammar:** `spotlight_query` keeps one meaning forever, so free text arrives as a separate tool rather than a breaking change or mutually exclusive parameters.

## Risks

- Clients will often write malformed queries; the error message and tool description carry the burden of recovery.
- TCC may silently filter results in protected locations unless the host app has Full Disk Access. Document once observed.
