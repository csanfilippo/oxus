# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`oxus` is an MCP (Model Context Protocol) server that exposes macOS Spotlight search to MCP clients over stdio. It is built with Swift Package Manager on the official [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) (product `MCP`). It exposes two tools: `spotlight_query` runs a raw Spotlight query and returns matching file paths; `search` finds files by name without Spotlight syntax.

## Commands

```sh
swift test --skip AcceptanceTests                # skip tests that hit real Spotlight
```

To exercise the server by hand, run the built binary directly instead of `swift run`, so that build output cannot mix with protocol traffic. The server stops as soon as stdin closes, before replying, so keep stdin open briefly with `sleep`:

```sh
{ printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"sh","version":"0"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"spotlight_query","arguments":{"query":"kMDItemFSName == \"Finder.app\""}}}'; sleep 1; } \
  | "$(swift build --show-bin-path)/oxus"
```

## Toolchain and compiler settings

- The minimum deployment target is macOS 27, the only version currently tested.
- Every target enables the `ApproachableConcurrency` upcoming feature through the shared `swiftSettings` in `Package.swift`; new targets must use it too.

## Structure

- `OxusServer` (library) builds the MCP `Server` through `makeOxusServer(spotlight:)`, registers the tool handlers, and defines the `Spotlight` port. All behaviour lives here; it never imports CoreServices.
- `CoreServicesAdapter` (library) implements `Spotlight` as `CoreServicesSpotlight` on `MDQuery`. It depends on `OxusServer`, never the other way round, and never imports `MCP`.
- `oxus` (executable) is the composition root: it passes `CoreServicesSpotlight()` to `makeOxusServer(spotlight:)` and connects the server to `StdioTransport`. Keep it a thin adapter.
- `OxusServerTests` drives the server through the SDK's `InMemoryTransport` and `Client`, against `SpySpotlight`. Tests exercise the protocol a real client sees, not handler internals.
- `CoreServicesAdapterTests` tests `CoreServicesSpotlight` directly against real Spotlight, querying always-indexed system files (e.g. `Finder.app`). Every behaviour `SpySpotlight` assumes (such as honouring `limit`) needs a matching test here.
- `AcceptanceTests` drives the server through an MCP `Client` wired to the real `CoreServicesSpotlight`.
- Stdout carries JSON-RPC only. Never `print` from the server; anything diagnostic goes to stderr.
- Unknown tool names throw `MCPError.invalidParams`, which becomes a protocol error. Failures of a known tool are returned as a result with `isError: true`.

## Increments

Each increment is documented in `docs/increments/NNN-<slug>.md` (goal, status, contract, out of scope, design, open decisions, risks). Update its status and decisions as work progresses. Its TDD test list lives in `docs/tests/increment-N-test-list.txt`.
