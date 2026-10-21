# Increment 1 — `spotlight_query`

**Status:** Done (2026-10-14). The description contract was met only on 2026-10-21.

## Goal

Replace `hello` with a `spotlight_query` tool that runs a raw Spotlight query and returns the paths of matching files. The thinnest slice that wires the MCP contract, a Spotlight port and its real adapter end to end, with no query interpretation.

## Contract

- Input: `query` (string, required, Spotlight query syntax, e.g. `kMDItemFSName == "*.pdf"c`), `limit` (integer, optional, default 25, minimum 1, capped at 100). The schema advertises both bounds.
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
- **Targets:** `CoreServicesSpotlight` lives in its own `CoreServicesAdapter` library, which depends on `OxusServer`; the compiler enforces that the port never depends on CoreServices. `oxus` is the composition root wiring the adapter into the server. Tests split the same way: `OxusServerTests` (protocol, with a fake), `CoreServicesAdapterTests` (real Spotlight), `AcceptanceTests` (MCP client against the real adapter).
- **Adapter tests:** a few tests against real Spotlight querying always-indexed system files (e.g. `Finder.app`). They depend on the machine, not on time (a query takes ~30 ms), so they are isolated by test target rather than by tag. Temporary directories are not indexed, and polling for a freshly indexed file would make tests timing-dependent.

## Decisions

- **Raw query language first:** passing the query through untouched keeps this increment about wiring. Free text follows in increment 2.
- **Tool named after its grammar:** `spotlight_query` keeps one meaning forever, so free text arrives as a separate tool rather than a breaking change or mutually exclusive parameters.
- **No matches is success with empty content:** every content block is a path, so the result has a single meaning.
- **Limit above the cap is clamped,** not rejected: a large limit means "as many as possible".
- **No truncation signal yet:** it belongs with pagination.
- **The description states the path cap:** `spotlight_query` shares `Limit` with `search`, so it has the same risk of presenting a truncated list as complete, and like `search` it states "Returns at most 100 paths".
- **The tool is annotated `readOnlyHint: true`** (2026-10-21): it never modifies its environment, and the default is `false`. `destructiveHint` and `idempotentHint` are left unset because they are meaningful only when `readOnlyHint` is `false`. No protocol test covers the annotation yet.
- **The port uses typed throws (`throws(SpotlightError)`):** the adapter must translate every CoreServices failure into a `SpotlightError` case, so the server knows the complete set of failures it has to report. `MDQueryCreate` returning `NULL` is `.malformedQuery`; `MDQueryExecute` returning `false` is `.executionFailed`, reported rather than passed off as "no matches". No known query triggers the latter, so only the server's handling of it is tested, through a stub.

## Test list

`docs/tests/increment-1-test-list.txt`

## Risks

- Clients will often write malformed queries; the error message and tool description carry the burden of recovery.
- TCC may silently filter results in protected locations unless the host app has Full Disk Access. Document once observed.
