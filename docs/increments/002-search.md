# Increment 2 — `search` by name

**Status:** Done (2026-10-16)

## Goal

Add a `search` tool that finds files whose name contains a given text, so clients can find files without writing Spotlight query syntax. It is the first slice of a structured search: the client's LLM interprets the user's natural-language request and expresses it as typed filters; oxus compiles the filters into a Spotlight query.

## Contract

- Input: `name_contains` (string, required), `limit` (integer, optional, same default, minimum and cap as `spotlight_query`).
- Matching is on the display name (`kMDItemDisplayName`), case- and diacritic-insensitive: `name_contains: "report"` matches `Report-Final.PDF`, and `"calcolatri"` matches Calculator.app on an Italian Mac.
- Characters in `name_contains` are matched literally: `"`, `\` and `*` never alter the query.
- Output: same as `spotlight_query`, one text content block per matching path, in Spotlight's order.
- Missing, blank, or non-string `name_contains` returns a result with `isError: true` and a message the client can act on.
- Invalid `limit` is handled exactly as in `spotlight_query`.
- The tool description states that results are capped at 100, so a request for "all" files returns at most 100 paths.
- `spotlight_query` stays unchanged.

## Out of scope

Filtering by kind (increment 3), starts with / ends with / exact name, dates, size, text content, OR within a single call, pagination.

## Design

- **The server never interprets natural language.** The client's LLM turns "find the files whose name contains xyz" into `search(name_contains: "xyz")`. An OR between filters is expressed as several calls.
- **Flat, optional filters combined with AND, not an expression tree.** A recursive schema (`$ref`, `anyOf`) is rejected by many LLM clients; a flat object of typed fields is what models fill most reliably. Later filters are added as new optional fields.
- **`SearchCriteria` value object:** parses the tool arguments and compiles them into a Spotlight query string, e.g. `name_contains: "xyz"` → `kMDItemDisplayName == "*xyz*"cd`. Escapes `\` first, then `"` and `*`, so user input cannot change the query (query injection). Pure logic, test-driven with unit tests, separate from MCP and Spotlight.
- **Reuses the `Spotlight` port and `Limit` unchanged.** `search` is a translator in front of the same port; `CoreServicesSpotlight` needs no change.
- **Routing two tools:** with a second tool, the `CallTool` handler dispatches on the tool name. Each tool becomes its own type behind a shared "handle these arguments" method (Command pattern), so `makeOxusServer` only routes. The refactor happens when `search` arrives, not before.

## Decisions

- **Name contains, not exact name, as the smallest slice:** both need the second tool, routing, compilation and escaping; "contains" adds only the `*…*cd` wrapping and is what users actually ask for.
- **Arguments use snake_case** (`name_contains`), matching the tool names.
- **Match the display name, not the file system name:** `kMDItemDisplayName` is what users see in Finder, localized and usually without extension; `kMDItemFSName` would miss "Calcolatrice" and match every `.pdf` for "pdf".
- **`?` is not a wildcard:** `kMDItemFSName == "Finde?.app"` matches nothing, so only `\`, `"` and `*` are escaped.
- **Limit is tested for wiring only:** its rules are already covered through `spotlight_query`.
- **The tool is annotated `readOnlyHint: true`** (2026-10-21), like `spotlight_query`; see increment 1. No protocol test covers the annotation yet.

## Test list

`docs/tests/increment-2-test-list.txt`

## Risks

- Users who ask for "all" files get at most 100 paths until pagination exists; the tool description must make that explicit, or the model will present a truncated list as complete.
