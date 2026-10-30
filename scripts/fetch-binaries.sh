#!/usr/bin/env bash
# Downloads AlprKit.xcframework for the version in package.json into ios/Frameworks.
set -euo pipefail

cd "$(dirname "$0")/.."
version=$(node -p "require('./package.json').version")
base="${ALPR_BASE_URL:-https://alpr.parkr.app}"
zip="AlprKit-$version.xcframework.zip"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$base/sdk/ios/$version/$zip" -o "$tmp/$zip"
expected=$(curl -fsSL "$base/sdk/ios/$version/$zip.sha256" | awk '{print $1}')
actual=$(shasum -a 256 "$tmp/$zip" | awk '{print $1}')
[ "$expected" = "$actual" ] || { echo "Checksum mismatch for $zip" >&2; exit 1; }

rm -rf ios/Frameworks/AlprKit.xcframework
mkdir -p ios/Frameworks
unzip -q "$tmp/$zip" -x "__MACOSX/*" -d ios/Frameworks
echo "AlprKit $version in ios/Frameworks"
