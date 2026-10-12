# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`oxus` is an MCP (Model Context Protocol) server that exposes macOS Spotlight search to MCP clients over stdio. It is built with Swift Package Manager on the official [MCP Swift SDK](https://github.com/modelcontextprotocol/swift-sdk) (product `MCP`). It currently exposes a single `hello` tool, a walking skeleton; no Spotlight code exists yet.

## Commands

```sh
swift build                 # debug build
swift build -c release      # release build
swift test                  # run all tests
swift test --filter HelloToolTests/greetsByName   # run a single test
```

To exercise the server by hand, run the built binary directly instead of `swift run`, so that build output cannot mix with protocol traffic:

```sh
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"sh","version":"0"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"hello","arguments":{"name":"Ada"}}}' \
  | "$(swift build --show-bin-path)/oxus"
```

## Toolchain and compiler settings

- `swift-tools-version: 6.4`, so the package builds in Swift 6 language mode with strict concurrency checking on.
- The minimum deployment target is macOS 27, the only version currently tested.
- Every target enables the `ApproachableConcurrency` upcoming feature through the shared `swiftSettings` in `Package.swift`; new targets must use it too.
- Dependency versions are pinned in `Package.resolved`, which is committed.

## Structure

- `OxusServer` (library) builds the MCP `Server` through `makeOxusServer()` and registers the tool handlers. All behaviour lives here.
- `oxus` (executable) only connects that server to `StdioTransport`. Keep it a thin adapter.
- `OxusServerTests` drives the server through the SDK's `InMemoryTransport` and `Client`. Tests exercise the protocol a real client sees, not handler internals.
- Stdout carries JSON-RPC only. Never `print` from the server; anything diagnostic goes to stderr.
- Unknown tool names throw `MCPError.invalidParams`, which becomes a protocol error. Failures of a known tool are returned as a result with `isError: true`.
