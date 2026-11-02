# Releasing oxus

How to publish a new version, e.g. `0.2.0`. A release produces a signed, notarized arm64 binary on GitHub Releases and points the Homebrew formula in [csanfilippo/homebrew-tap](https://github.com/csanfilippo/homebrew-tap) at it.

## One-time setup, per Mac

- **Developer ID certificate:** Xcode › Settings › Accounts › your team › Manage Certificates › + › Developer ID Application. `security find-identity -v -p codesigning` must list `Developer ID Application: Calogero Sanfilippo (924TRQMLE7)`.
- **Notarization credentials:** create an app-specific password at account.apple.com › Sign-In and Security › App-Specific Passwords, then run in Terminal (not through Claude Code's `!`, which cannot answer the password prompt):

  ```sh
  xcrun notarytool store-credentials oxus-notary --apple-id sanfilippo.calogero@gmail.com --team-id 924TRQMLE7
  ```

- **GitHub CLI:** `gh auth status` shows you logged in with the `repo` scope.
- **Homebrew:** `scripts/update-tap.sh` runs `brew style` on the formula.

## Steps

1. **Pick the version.** Follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html): while oxus is `0.x`, a breaking change to the command line or to a tool's arguments or results bumps the minor version, anything else the patch version.

2. **Set the version** in `Sources/OxusServer/Version.swift`:

   ```swift
   public let oxusVersion = "0.2.0"
   ```

3. **Update `CHANGELOG.md`.** Add `## [0.2.0] - YYYY-MM-DD` below `## [Unreleased]`, so the Unreleased entries fall under it and `## [Unreleased]` stays empty. Then update the links at the bottom:

   ```markdown
   [Unreleased]: https://github.com/csanfilippo/oxus/compare/v0.2.0...HEAD
   [0.2.0]: https://github.com/csanfilippo/oxus/compare/v0.1.0...v0.2.0
   [0.1.0]: https://github.com/csanfilippo/oxus/releases/tag/v0.1.0
   ```

4. **Run every test locally.** CI skips the tests that need real Spotlight, so this is the only place they run:

   ```sh
   swift test
   ```

5. **Commit and push**, then wait for CI to pass on `main`:

   ```sh
   git commit -am "chore: release 0.2.0"
   git push
   ```

6. **Tag and push the tag.** The script refuses to tag without a `## [0.2.0]` CHANGELOG section or with uncommitted changes:

   ```sh
   scripts/tag-release.sh
   git push origin v0.2.0
   ```

7. **Publish:**

   ```sh
   scripts/release.sh
   ```

   It takes a few minutes, mostly waiting for Apple. If macOS asks whether `codesign` may use your keychain, choose Always Allow. The script:
   1. builds the tagged code, not the working tree, for arm64 in a temporary worktree;
   2. signs the binary with the Developer ID, the hardened runtime and a secure timestamp;
   3. zips it as `oxus-macos-arm64.zip`, notarizes the zip, and stops if Apple does not accept it;
   4. creates the GitHub Release `v0.2.0` with the zip and its `.sha256`, using the CHANGELOG section as release notes;
   5. runs `scripts/update-tap.sh`, which points the formula at the new zip and pushes the tap.

8. **Check the release:**

   ```sh
   brew update && brew upgrade oxus && brew test oxus
   brew list --versions oxus        # oxus 0.2.0
   ```

   The README's manual install links follow the latest release, so they need no change.

## When something fails

- **Notarization not accepted:** the script prints the `xcrun notarytool log …` command that explains why, and stops before creating the release. If the fix is in the environment (certificate, credentials), run `scripts/release.sh` again. If it needs a code change, release it as the next patch version: never move a tag that is already pushed.
- **`gh release create` failed:** check `gh release view v0.2.0`. If there is no release, run `scripts/release.sh` again. If the release exists without its two files, delete it with `gh release delete v0.2.0 --yes`, which keeps the tag, then run `scripts/release.sh` again.
- **The release exists but the tap was not updated:** run `scripts/update-tap.sh`. It does nothing if the formula already points at the release, so it is safe to repeat.
- **A broken release is already published:** do not replace its files. Fix it and release the next patch version.
