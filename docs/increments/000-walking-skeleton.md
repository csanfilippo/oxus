# Increment 0 — Walking skeleton

**Status:** Done (`7517372`, 2026-10-13)

## Goal

Prove the delivery pipeline end to end before any Spotlight code exists: a Swift package that builds, an MCP server that speaks the protocol over stdio, and tests that drive it as a real client would.

## Delivered

- `hello` tool: greets `name`, or the world when no name is given.
- `OxusServer` library builds the `Server` through `makeOxusServer()` and owns all behaviour.
- `oxus` executable is a thin adapter connecting that server to `StdioTransport`.
- `OxusServerTests` drives the server through `InMemoryTransport` and `Client`.

## Decisions

- Tests exercise the protocol, not handler internals, so they survive any internal restructuring.
- Unknown tool names throw `MCPError.invalidParams` (a protocol error); failures of a known tool are results with `isError: true`.
- Stdout carries JSON-RPC only; diagnostics go to stderr.
