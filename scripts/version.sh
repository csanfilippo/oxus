#!/bin/bash
# Prints oxus's version from Sources/OxusServer/Version.swift, the one place it is set.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

version=$(sed -nE 's/^(public )?let oxusVersion = "(.+)"$/\2/p' Sources/OxusServer/Version.swift)
if [ -z "$version" ]; then
    echo "no oxusVersion in Sources/OxusServer/Version.swift" >&2
    exit 1
fi

echo "$version"
