# Release checklist

Steps to publish oxus as a public, installable MCP server.

## Blockers

- [x] Finish [increment 7](increments/007-protected-folders.md), so a folder macOS denies access to becomes an actionable error instead of silently missing results. Increments [8](increments/008-protected-subfolders.md) and [9](increments/009-unscoped-protected-folders.md) cover the folders denied inside a scope and in unscoped calls.
- [x] Add a README troubleshooting section on macOS privacy permissions: which app macOS asks about depends on what launched oxus (oxus itself under Claude Desktop, the terminal app under a terminal), how to grant or reset access, and that the access prompt blocks the tool call.

## Versioning

- [x] Keep the version in one place: `oxusVersion` in `Sources/OxusServer/Version.swift`; `scripts/tag-release.sh` derives the tag from it.
- [x] Add `CHANGELOG.md`.
- [x] Replace the README's "Status: early" with what is supported.
- [x] Tag `v0.1.0`: move the CHANGELOG's Unreleased entries under `## [0.1.0]`, commit, run `scripts/tag-release.sh`, and push the tag.

## CI

- [x] GitHub Actions workflow (`.github/workflows/ci.yml`) running `swift format lint --strict` and `swift test --skip AcceptanceTests --skip MacOSAdaptersTests` on the `xcode-27` preview image (macOS 27, Swift 6.4.2).
  - Real Spotlight is not tested in CI: on the runner, tests that query it hang, so `MacOSAdaptersTests` and `AcceptanceTests` run only locally. Run them before tagging a release.

## Distribution

- [x] Release binary, arm64 only (macOS 27 does not run on Intel).
- [x] Sign with a Developer ID and notarize; otherwise Gatekeeper blocks the downloaded binary and the client fails to launch it without a clear error. Requires a paid Apple Developer account.
- [x] Publish the binary on GitHub Releases with `scripts/release.sh`.
- [x] Homebrew tap ([csanfilippo/homebrew-tap](https://github.com/csanfilippo/homebrew-tap)), so users don't need the Swift 6.4 toolchain. Each release must update the formula's `url` and `sha256`.
- [ ] Optional: MCPB bundle for one-click install in Claude Desktop, and a listing in the official MCP registry.
- [x] README: install instructions ahead of "Build from source".

## Repo hygiene

- [x] `SECURITY.md`: oxus exposes file paths to a model, so give leak reports a channel.
- [x] Enable private vulnerability reporting once the repository is public; `SECURITY.md` points reporters to it.
- [x] Repository description.
- [x] Upload `.github/assets/oxus-social-preview.png` as the social preview.
- [x] Make the repository public.

## Decisions

- Contributions are not accepted for now; the README says so. If that changes, add `CONTRIBUTING.md` describing the increments and test-list workflow.
