#!/bin/bash
# Builds, signs and notarizes the arm64 oxus binary for the tagged version, then publishes it as a GitHub Release.
# Needs a Developer ID Application certificate in the keychain and a notarytool keychain profile.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

signing_identity=${OXUS_SIGNING_IDENTITY:-Developer ID Application}
notary_profile=${OXUS_NOTARY_PROFILE:-oxus-notary}
bundle_identifier=io.github.csanfilippo.oxus

version=$(sed -n 's/^let oxusVersion = "\(.*\)"$/\1/p' Sources/OxusServer/Version.swift)
tag="v$version"

if ! git ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null; then
    echo "$tag is not on origin; run scripts/tag-release.sh, then: git push origin $tag" >&2
    exit 1
fi

# Builds the tagged code, not the working tree, so the binary matches the tag whatever is checked out.
source_tree=$(mktemp -d)
trap 'git worktree remove --force "$source_tree"' EXIT
git worktree add --detach "$source_tree" "$tag"

swift build --package-path "$source_tree" -c release --arch arm64
binary="$(swift build --package-path "$source_tree" -c release --arch arm64 --show-bin-path)/oxus"

# Notarization requires the hardened runtime and a secure timestamp.
codesign --force --sign "$signing_identity" --identifier "$bundle_identifier" --options runtime --timestamp "$binary"
codesign --verify --strict --verbose=2 "$binary"

dist=.build/dist
# No version in the name, so the README can link to releases/latest/download/ for every release.
archive="$dist/oxus-macos-arm64.zip"
rm -rf "$dist"
mkdir -p "$dist"
ditto -c -k --norsrc "$binary" "$archive"

submission=$(xcrun notarytool submit "$archive" --keychain-profile "$notary_profile" --wait --output-format json)
status=$(plutil -extract status raw - <<<"$submission")
if [ "$status" != "Accepted" ]; then
    id=$(plutil -extract id raw - <<<"$submission")
    echo "notarization finished with status $status; see: xcrun notarytool log $id --keychain-profile $notary_profile" >&2
    exit 1
fi

(cd "$dist" && shasum -a 256 "$(basename "$archive")" > "$(basename "$archive").sha256")

notes=$(awk -v heading="## [$version]" '
    index($0, heading) == 1 { in_section = 1; next }
    in_section && (/^## \[/ || /^\[/) { exit }
    in_section { print }
' CHANGELOG.md)

gh release create "$tag" "$archive" "$archive.sha256" --verify-tag --title "$tag" --notes "$notes"

scripts/update-tap.sh
