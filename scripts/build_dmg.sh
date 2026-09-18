#!/bin/zsh

set -euo pipefail

script_directory=${0:A:h}
project_root=${script_directory:h}
build_directory="$project_root/build/Release"
derived_data_directory="$project_root/build/DerivedData"
staging_directory=$(mktemp -d "${TMPDIR:-/tmp}/ntfy-tray-dmg.XXXXXX")

cleanup() {
    rm -rf "$staging_directory"
}

trap cleanup EXIT

cd "$project_root"

xcodebuild \
    -quiet \
    -project ntfy-tray.xcodeproj \
    -scheme ntfy-tray \
    -configuration Release \
    -destination 'platform=macOS' \
    -derivedDataPath "$derived_data_directory" \
    build \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY=- \
    DEVELOPMENT_TEAM= \
    CONFIGURATION_BUILD_DIR="$build_directory"

app_path="$build_directory/ntfy-tray.app"
if [[ ! -d "$app_path" ]]; then
    print -u2 "Expected app bundle was not built: $app_path"
    exit 1
fi

codesign --verify --deep --strict --verbose=2 "$app_path"

version=${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app_path/Contents/Info.plist")}
if [[ -z "$version" || "$version" == *"/"* ]]; then
    print -u2 "VERSION must be a non-empty filename component."
    exit 1
fi

cp -R "$app_path" "$staging_directory/"
ln -s /Applications "$staging_directory/Applications"

dmg_path="$build_directory/ntfy-tray-$version.dmg"
hdiutil create \
    -volname "ntfy-tray" \
    -srcfolder "$staging_directory" \
    -format UDZO \
    -ov \
    "$dmg_path"
hdiutil verify "$dmg_path"

print "Created $dmg_path"
