# Increment 10 — Version flag

**Status:** Planned

## Goal

Let anyone see which oxus they run, however they installed it. Today only Homebrew users can (`brew list --versions oxus`); a binary installed from the release zip cannot report its version, and `oxus --version` starts a server that waits on stdin.

## Contract

- `oxus --version` prints `oxus <version>` and a newline to stdout, e.g. `oxus 0.1.0`, and exits with status 0. It starts no server and reads nothing from stdin.
- `<version>` is `oxusVersion`, the version the release scripts tag and publish.
- `oxus` with no arguments starts the server over stdio, as before.
- Any other arguments, including `--version` followed by anything, print `usage: oxus [--version]` to stderr and exit with status 64 (`EX_USAGE`), starting no server.

## Out of scope

- `--help`, `-V` and any other flag.
- Changing `serverInfo.version`, which already reports `oxusVersion`.

## Design

- The `oxus` executable checks its arguments before building the server, so the flag never reaches `OxusServer` and the composition root stays a thin adapter. Printing to stdout is safe: in this mode there is no server, so no JSON-RPC to corrupt.
- `oxusVersion` is internal to `OxusServer` today; the executable needs to read it.
- The tests live in a new `oxusTests` target, which depends on the `oxus` executable. They run the built binary as a separate process and check what a user sees: its stdout, its stderr and its exit status.
- Once a release ships the flag, the Homebrew formula's test and step 8 of `docs/releasing.md` can check `oxus --version` instead of sending an MCP `initialize`.

## Manual check

Install the release from the zip and from Homebrew, and run `oxus --version` for each.

## Open decisions

None.

## Decisions

- **Other arguments are rejected** (2026-11-03): oxus accepts no arguments or exactly `--version`, and rejects anything else on stderr with exit status 64, instead of ignoring it as today. Ignoring hides mistakes: a mistyped `--verison`, or `"args": ["--verbose"]` in a client's config, silently starts a server that does nothing different. Rejecting costs nothing more, since both are the same three-case `switch` on the arguments. A client that adds arguments of its own would break; Claude Code, Claude Desktop and the planned MCPB bundle add none.
- **A new `oxusTests` target** (2026-11-03): named after the target it tests, like `OxusServerTests` and `MacOSAdaptersTests`. Not `AcceptanceTests`, which groups the tests that need real Spotlight and real folders and is skipped in CI for that reason; these tests need neither, so CI runs them. Not `OxusServerTests`, which tests the protocol and never sees the flag. The tests run the binary as a process rather than importing the `oxus` module, so they cover the printing and the exit status, and the arguments check needs no visibility for tests' sake.

## Test list

Not written yet.

## Risks

- **The release scripts read the version declaration literally.** `scripts/tag-release.sh`, `scripts/release.sh` and `scripts/update-tap.sh` match the line `let oxusVersion = "…"`. Making it `public let` breaks all three until their pattern changes with it.
- **Finding the binary from a test.** A test has to locate the `oxus` product in the build folder, and the test target has to depend on the executable so that `swift test` builds it first.
