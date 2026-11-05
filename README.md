<h1 align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/oxus-logo-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset=".github/assets/oxus-logo-light.svg">
    <img alt="oxus" src=".github/assets/oxus-logo-light.svg" width="320">
  </picture>
</h1>

An [MCP](https://modelcontextprotocol.io) server that exposes macOS Spotlight search to MCP clients over stdio.

> **Status:** 0.2.0. `spotlight_query` runs raw Spotlight queries, and `search` finds files by name, kind and folder without query syntax; both report the Downloads, Documents and Desktop folders macOS privacy protection hides from Spotlight. `oxus --version` reports the installed version. Runs on macOS 27; checked by hand with Claude Code and Claude Desktop.

## Requirements

- macOS 27 on Apple silicon

## Install

With [Homebrew](https://brew.sh):

```sh
brew install csanfilippo/tap/oxus
```

The binary is then at `$(brew --prefix)/bin/oxus`, usually `/opt/homebrew/bin/oxus`.

### Without Homebrew

Each [release](https://github.com/csanfilippo/oxus/releases) has a signed and notarized binary. To install the latest one in `~/.local/bin`:

```sh
curl -fLO https://github.com/csanfilippo/oxus/releases/latest/download/oxus-macos-arm64.zip
curl -fLO https://github.com/csanfilippo/oxus/releases/latest/download/oxus-macos-arm64.zip.sha256
shasum -a 256 -c oxus-macos-arm64.zip.sha256
unzip oxus-macos-arm64.zip
mkdir -p ~/.local/bin && mv oxus ~/.local/bin/
```

The binary is then at `~/.local/bin/oxus`; MCP clients need its absolute path, which `echo ~/.local/bin/oxus` prints.

### Build from source

Building needs the Swift 6.4 toolchain:

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

## Privacy

oxus runs locally and makes no network requests, but it gives the connected MCP client the paths of any file Spotlight has indexed for your user, including files in your home folder. If the client is backed by a hosted model, those paths, and the queries that produced them, are sent to that model's provider.

- Results are paths only; oxus never returns file contents. A `spotlight_query` can still match on metadata or indexed text, so a result can reveal what a file contains.
- oxus has no allowlist of folders. To keep a location out of its results, exclude it from Spotlight in System Settings, under Spotlight's privacy settings.

## Tools

Without access to `~/Downloads`, `~/Documents` or `~/Desktop`, Spotlight silently leaves out their files. So a `spotlight_query`, a `search` without a `folder`, and a `search` whose `folder` contains one of them also return `unreadableFolders`: one `{"path": ..., "fix": ...}` per folder macOS privacy protection denies to oxus, the fix naming the Files and Folders setting to change.

When more matches exist than `limit` allows, a result also carries `"truncated": true` next to `paths`, so raise `limit` or narrow the search. A result with every match has no `truncated` key.

### `spotlight_query`

Runs a raw [Spotlight query](https://developer.apple.com/library/archive/documentation/Carbon/Conceptual/SpotlightQuery/Concepts/QueryFormat.html) and returns the paths of matching files.

| Argument | Type | Required | Description |
|---|---|---|---|
| `query` | string | yes | Spotlight query syntax, e.g. `kMDItemFSName == "*.pdf"c` |
| `limit` | integer | no | Maximum number of paths, default 25, capped at 100 |

The result is `{"paths": [...]}` in Spotlight's order, as structured content and as JSON in a single text block, e.g. `{"paths":["/System/Library/CoreServices/Finder.app"]}`.

To try a query before sending it, run it with `mdfind`:

```sh
mdfind 'kMDItemFSName == "Finder.app"'
```

### `search`

Finds files by name, kind, folder, or any combination of them, without Spotlight query syntax. At least one of `name_contains`, `kind` and `folder` is required; when several are given, a file must match all of them.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name_contains` | string | no | Text the file's name must contain, ignoring case and diacritics |
| `kind` | string | no | One of `image`, `movie`, `audio`, `pdf`, `folder`, `application`; a kind includes its subtypes, e.g. `image` matches PNG, JPEG and HEIC |
| `folder` | string | no | The folder to search, including its subfolders: an absolute path, `~` alone, or a path starting with `~/` |
| `limit` | integer | no | Maximum number of paths, default 25, capped at 100 |

The result is `{"paths": [...]}` in Spotlight's order, as structured content and as JSON in a single text block, e.g. `{"paths":["/System/Library/CoreServices/Finder.app"]}`.

A `folder` that cannot be searched returns an error result naming the expanded path and the fix, instead of an empty list:

| `folder` | Error result |
|---|---|
| does not exist | asks to correct the path |
| is a file | suggests searching its parent folder |
| is a package, e.g. an `.app` bundle | suggests searching elsewhere, since Spotlight indexes nothing inside packages |
| is denied by macOS privacy protection | names the setting to change: System Settings › Privacy & Security › Files and Folders › Downloads, Documents or Desktop when the folder is in one of them, otherwise Privacy & Security; granted to `oxus` if it is listed there, otherwise to the app that launched oxus |
| lacks read permission | asks to grant your user read permission on it |
| cannot be read for another reason | gives the reason macOS reports, e.g. `Input/output error` |

## Troubleshooting

### Files in Downloads, Documents or Desktop are missing

macOS privacy protection decides whether oxus may read `~/Downloads`, `~/Documents` and `~/Desktop`. Without access, Spotlight leaves their files out with no error. oxus reports each denied folder in `unreadableFolders`, or returns an error when the `folder` you search is inside one.

Which app macOS asks about depends on what launched oxus:

- **Claude Desktop:** oxus itself. The first search that reaches one of these folders shows "oxus would like to access files in the Downloads folder" (or Documents, or Desktop).
- **A terminal**, e.g. Claude Code in iTerm: the terminal app. No prompt names oxus; the terminal's access applies.

To grant access, open System Settings › Privacy & Security › Files and Folders and turn on the folder for oxus if it is listed there, otherwise for the app that launched oxus.

The tool call waits while the access prompt is open. If the client gives up first, answer the prompt and run the search again.

To be asked again, reset the decision with `tccutil reset SystemPolicyDownloadsFolder` (or `SystemPolicyDocumentsFolder`, `SystemPolicyDesktopFolder`). This clears that folder's decision for every app, not only oxus.

A rebuilt or updated oxus may be treated as a new app, so macOS may ask again.

## Development

```sh
swift test                                # all tests
swift test --skip AcceptanceTests         # skip the end-to-end tests
git config core.hooksPath .githooks       # once per clone: lint staged Swift files before each commit
```

| Target | Role |
|---|---|
| `OxusServer` | Builds the MCP server and defines the `Spotlight` and `FileSystem` ports |
| `MacOSAdapters` | Implements `Spotlight` on CoreServices (`MDQuery`) and `FileSystem` on `FileManager` |
| `oxus` | Executable; wires the adapters into the server over stdio |
| `OxusServerTests` | Protocol tests through an MCP client, against a fake Spotlight and fake file systems |
| `MacOSAdaptersTests` | Adapter tests against real Spotlight and real folders |
| `AcceptanceTests` | End-to-end tests through an MCP client, against real Spotlight and real folders |

Work is planned in increments: each one is described in [`docs/increments`](docs/increments), next to its TDD test list. The modules and how they depend on each other are drawn in [`docs/design/architecture.md`](docs/design/architecture.md), and how tool arguments are read is described in [`docs/design/tool-arguments.md`](docs/design/tool-arguments.md). Releases follow [`docs/releasing.md`](docs/releasing.md).

## Contributing

oxus does not accept pull requests for now. Bug reports and feature requests are welcome as issues; report security issues as described in [SECURITY.md](SECURITY.md).

## Name

Oxus is the ancient name of the Amu Darya, one of the great rivers of Central Asia. Its banks gave up the Oxus Treasure, a hoard of Achaemenid gold and silver found in the 1870s and now held at the British Museum. oxus does the same for your Mac: it digs through what Spotlight has indexed and brings the files you are looking for to the surface.

## License

[MIT](LICENSE)
