<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/oxus-logo-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset=".github/assets/oxus-logo-light.svg">
    <img alt="oxus" src=".github/assets/oxus-logo-light.svg" width="320">
  </picture>
</h1>

An [MCP](https://modelcontextprotocol.io) server that exposes macOS Spotlight search to MCP clients over stdio.

> **Status:** early. `spotlight_query` runs raw Spotlight queries, and `search` finds files by name and kind without query syntax.

## Requirements

- macOS 27
- Swift 6.4 toolchain

## Build

```sh
swift build -c release
```

The binary is written to `$(swift build -c release --show-bin-path)/oxus`.

## Use with an MCP client

oxus speaks MCP over stdio, so any client that can launch a local command can use it.

Claude Code:

```sh
claude mcp add oxus -- /absolute/path/to/oxus
```

Claude Desktop (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "oxus": { "command": "/absolute/path/to/oxus" }
  }
}
```

## Tools

### `spotlight_query`

Runs a raw [Spotlight query](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html) and returns the paths of matching files.

| Argument | Type | Required | Description |
|---|---|---|---|
| `query` | string | yes | Spotlight query syntax, e.g. `kMDItemFSName == "*.pdf"c` |
| `limit` | integer | no | Maximum number of paths, default 25, capped at 100 |

The result has one text content block per matching path, in Spotlight's order.

To try a query before sending it, run it with `mdfind`:

```sh
mdfind 'kMDItemFSName == "Finder.app"'
```

### `search`

Finds files by name, kind, or both, without Spotlight query syntax. At least one of `name_contains` and `kind` is required; when both are given, a file must match both.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name_contains` | string | no | Text the file's name must contain, ignoring case and diacritics |
| `kind` | string | no | One of `image`, `movie`, `audio`, `pdf`, `folder`, `application`; a kind includes its subtypes, e.g. `image` matches PNG, JPEG and HEIC |
| `limit` | integer | no | Maximum number of paths, default 25, capped at 100 |

The result has one text content block per matching path, in Spotlight's order.

## Development

```sh
swift test
```

| Target | Role |
|---|---|
| `OxusServer` | Builds the MCP server and defines the `Spotlight` port |
| `CoreServicesAdapter` | Implements the port on CoreServices (`MDQuery`) |
| `oxus` | Executable; wires the adapter into the server over stdio |
| `OxusServerTests` | Protocol tests through an MCP client, against a fake Spotlight |
| `CoreServicesAdapterTests` | Adapter tests against real Spotlight |
| `AcceptanceTests` | End-to-end tests through an MCP client, against real Spotlight |

Work is planned in increments: each one is described in [`docs/increments`](docs/increments) and its TDD test list lives in [`docs/tests`](docs/tests).

## Name

Oxus is the ancient name of the Amu Darya, one of the great rivers of Central Asia. Its banks gave up the Oxus Treasure, a hoard of Achaemenid gold and silver found in the 1870s and now held at the British Museum. oxus does the same for your Mac: it digs through what Spotlight has indexed and brings the files you are looking for to the surface.

## License

[MIT](LICENSE)
