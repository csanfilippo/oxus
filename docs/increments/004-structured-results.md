# Increment 4 — Structured results

**Status:** Proposed

## Goal

Return search results in a form every MCP client hands to its model intact. Today each path is its own text content block, and Claude Code joins the blocks with no separator, so the model receives one string of paths stuck together and has to guess where each path ends.

## Contract

- `spotlight_query` and `search` advertise an `outputSchema`: an object with a required `paths` array of strings.
- A successful result carries `structuredContent: {"paths": [...]}`, in Spotlight's order, and one text content block holding the same object serialized as JSON.
- A query matching no files returns `{"paths": []}` in both, with `isError: false`.
- Error results are unchanged: one text block with a message and `isError: true`, with no `structuredContent`.
- Replaces the one-text-block-per-path output of increments 1–3; inputs, limits and error messages stay unchanged.

## Out of scope

Metadata per path (name, kind, size, dates, photo information), structured errors, pagination, `resource_link` content, a version bump.

## Design

- **Structured content plus a JSON text mirror,** as MCP 2025-06-18 recommends: clients that read `structuredContent` get typed data, and clients that only read text get the same data, unambiguous even for paths containing quotes, backslashes or newlines.
- **`{"paths": [...]}` is an object, not a bare array:** MCP requires `structuredContent` to be an object, and the object leaves room for later fields.
- **Tests read the full result:** the SDK's `client.callTool(name:arguments:)` returns only `content` and `isError`, so tests that check `structuredContent` need the whole `CallTool.Result`.

## Decisions

- **Both tools change together:** they share the output format, and keeping them aligned avoids two formats for the same kind of result.
- **Paths only:** no `count`, and no per-path objects until an increment needs metadata.
- **The text mirror is the same JSON,** not one path per line: it is unambiguous, and identical in content to `structuredContent`.
- **Version stays 0.1.0:** nothing has been released, so the first public tag carries the new format.

## Test list

`docs/tests/increment-4-test-list.txt`

## Risks

- How clients other than Claude Code treat several text blocks is unverified; after this increment a result is a single block, so it no longer matters, but the fix itself needs a manual check in Claude Code.
- Clients that validate `structuredContent` against `outputSchema` reject a successful result that does not match; the unit tests must check the schema and the result together.
