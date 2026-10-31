#!/usr/bin/env bash
# Downloads AlprKit.xcframework for the version in package.json into ios/Frameworks.
set -euo pipefail

cd "$(dirname "$0")/.."
version=$(node -p "require('./package.json').version")
repo="parkr-app/alpr-ios"
zip="AlprKit-$version.xcframework.zip"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# The zip is a GitHub release asset on alpr-ios; its checksum comes from Package.swift at the
# same tag, which Swift Package Manager also verifies.
curl -fsSL "https://github.com/$repo/releases/download/$version/$zip" -o "$tmp/$zip"
expected=$(curl -fsSL "https://raw.githubusercontent.com/$repo/$version/Package.swift" | sed -n 's/.*checksum: "\([0-9a-f]*\)".*/\1/p')
actual=$(shasum -a 256 "$tmp/$zip" | awk '{print $1}')
[ -n "$expected" ] && [ "$expected" = "$actual" ] || { echo "Checksum mismatch for $zip" >&2; exit 1; }

rm -rf ios/Frameworks/AlprKit.xcframework
mkdir -p ios/Frameworks
unzip -q "$tmp/$zip" -x "__MACOSX/*" -d ios/Frameworks
echo "AlprKit $version in ios/Frameworks"
