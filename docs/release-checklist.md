# Release checklist

Steps to publish oxus as a public, installable MCP server.

## Blockers

- [x] Finish [increment 7](increments/007-protected-folders.md), so a folder macOS denies access to becomes an actionable error instead of silently missing results. Increments [8](increments/008-protected-subfolders.md) and [9](increments/009-unscoped-protected-folders.md) cover the folders denied inside a scope and in unscoped calls.
- [x] Add a README troubleshooting section on macOS privacy permissions: which app macOS asks about depends on what launched oxus (oxus itself under Claude Desktop, the terminal app under a terminal), how to grant or reset access, and that the access prompt blocks the tool call.

## Versioning

- [ ] Keep the version in one place; `"0.1.0"` is hard-coded in `Sources/OxusServer/OxusServer.swift` and will drift from git tags.
- [x] Add `CHANGELOG.md`.
- [ ] Replace the README's "Status: early" with what is supported.
- [ ] Tag `v0.1.0`.

## CI

- [ ] GitHub Actions workflow running `swift test --skip AcceptanceTests` and `swift format lint`.
  - Risk: `MacOSAdaptersTests` hit real Spotlight, which may be disabled or unindexed on hosted runners; a hosted macOS 27 / Swift 6.4 image may not exist yet. Either skip that target in CI or use a self-hosted runner.

## Distribution

- [ ] Release binary, arm64 only (macOS 27 does not run on Intel).
- [ ] Sign with a Developer ID and notarize; otherwise Gatekeeper blocks the downloaded binary and the client fails to launch it without a clear error. Requires a paid Apple Developer account.
- [ ] Publish the binary on GitHub Releases.
- [ ] Homebrew tap, so users don't need the Swift 6.4 toolchain.
- [ ] Optional: MCPB bundle for one-click install in Claude Desktop, and a listing in the official MCP registry.
- [ ] README: install instructions ahead of "Build from source".

## Repo hygiene

- [ ] `SECURITY.md`: oxus exposes file paths to a model, so give leak reports a channel.
- [ ] Repository description (currently empty).
- [ ] Upload `.github/assets/oxus-social-preview.png` as the social preview.
- [ ] Make the repository public.

## Open decisions

- Are contributions welcome? If yes, add `CONTRIBUTING.md` describing the increments and test-list workflow; if not, say so in the README.
