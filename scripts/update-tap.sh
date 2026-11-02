#!/bin/bash
# Points the Homebrew formula at the GitHub Release of the version in Sources/OxusServer/Version.swift.
# Safe to run again: it does nothing when the formula already points at that release.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

tap_repository=csanfilippo/homebrew-tap

version=$(sed -n 's/^let oxusVersion = "\(.*\)"$/\1/p' Sources/OxusServer/Version.swift)
url="https://github.com/csanfilippo/oxus/releases/download/v$version/oxus-macos-arm64.zip"

# The checksum of what was published, not of a local build.
sha256=$(curl -fsSL "$url.sha256" | cut -d ' ' -f 1)
if ! [[ "$sha256" =~ ^[0-9a-f]{64}$ ]]; then
    echo "no valid checksum at $url.sha256; publish the release first" >&2
    exit 1
fi

tap=$(mktemp -d)
trap 'rm -rf "$tap"' EXIT
gh repo clone "$tap_repository" "$tap" -- --quiet

formula="$tap/Formula/oxus.rb"
sed -i '' -e "s|^  url \".*\"$|  url \"$url\"|" -e "s|^  sha256 \".*\"$|  sha256 \"$sha256\"|" "$formula"

if git -C "$tap" diff --quiet; then
    echo "the formula already points at oxus $version"
    exit 0
fi

brew style "$formula"
git -C "$tap" commit -q -am "oxus $version"
git -C "$tap" push -q
echo "pointed $tap_repository at oxus $version"
