# Increment 2 — `search`

**Status:** Proposed

## Goal

Add a `search` tool that accepts free text, so clients can find files without knowing Spotlight's query syntax.

## Contract

- Input: `text` (string, required), `limit` (integer, optional, same default and cap as `spotlight_query`).
- Output: same as `spotlight_query`.
- `spotlight_query` stays unchanged.

## Design

- **`SearchQuery` value object:** turns free text into a Spotlight query string (match on display name or text content, case- and diacritic-insensitive), escaping `"` and `\` so input cannot alter the query's meaning. Pure logic, test-driven in isolation.
- Reuses the `Spotlight` port from increment 1.

## Open decisions

- Which attributes free text matches, and how multiple words combine.
