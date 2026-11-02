# Increment 10 — MCP bundle and registry listing

**Status:** Planned, optional

## Goal

Install oxus in Claude Desktop with a double click, without Homebrew or editing `claude_desktop_config.json`, and make it discoverable in the official MCP Registry.

## Contract

- Each release also publishes `oxus.mcpb`: an MCP bundle holding the notarized binary and a `manifest.json` that declares it as a `binary` server for `darwin`, launched as `${__dirname}/server/oxus`, and lists `spotlight_query` and `search`.
- The registry lists oxus as `io.github.csanfilippo/oxus`, with the release's `.mcpb` and its SHA-256 as its package.
- The README has a Claude Desktop install line ahead of Homebrew.

## Out of scope

- Changes to the server or its tools.
- Intel Macs and macOS versions before 27.

## Design

- The manifest lives in the repository, outside `Sources`, with its version set from `oxusVersion` at release time.
- `scripts/release.sh` builds the bundle with the `@anthropic-ai/mcpb` CLI from the binary it already signed and notarized, and attaches it to the release; `scripts/update-tap.sh` stays as it is.
- The registry entry is a `server.json` published with `mcp-publisher`, authenticated through GitHub; MCPB is the registry package type that fits a native macOS binary.

## Manual check

Install the bundle in Claude Desktop, run both tools, and see the Downloads access prompt name oxus.

## Open decisions

- Whether to sign the bundle with `mcpb sign`, on top of the notarized binary inside it.
- Whether the registry entry is published by `scripts/release.sh` or by hand when the listing changes.

## Risks

- **Unchecked details.** The manifest fields, the `binary` server type and the registry's MCPB package type are described from memory; check them against the current MCPB and registry specs before writing anything.
- **No platform guard.** The manifest may not be able to require Apple silicon or macOS 27, so the README must say so.
- **No updates for a bundle installed from a file.** Users may need to install each release's bundle again.
- **More release outputs.** Each release adds a bundle and possibly a registry entry, so both must be steps in `scripts/release.sh`, not manual ones.
