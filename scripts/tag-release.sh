#!/bin/bash
# Tags the current commit with the version scripts/version.sh reads, so the tag cannot drift from it.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

version=$(scripts/version.sh)

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
