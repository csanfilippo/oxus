#!/bin/bash
# Tags the current commit with the version in Sources/OxusServer/Version.swift, so the tag cannot drift from it.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

version=$(sed -n 's/^let oxusVersion = "\(.*\)"$/\1/p' Sources/OxusServer/Version.swift)
if [ -z "$version" ]; then
    echo "no oxusVersion found in Sources/OxusServer/Version.swift" >&2
    exit 1
fi

if ! grep -q "^## \[$version\]" CHANGELOG.md; then
    echo "CHANGELOG.md has no '## [$version]' section; move the Unreleased entries under it first" >&2
    exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
    echo "the working tree is not clean; commit or stash first" >&2
    exit 1
fi

git tag -a "v$version" -m "v$version"
echo "tagged v$version; push it with: git push origin v$version"
