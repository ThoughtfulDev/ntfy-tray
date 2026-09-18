# Develop ntfy-tray

[← Back to the README](../README.md)

## Requirements

- A Mac running macOS 26.5 or later
- A current Xcode version with the macOS 26 SDK

## Open the project

Open [ntfy-tray.xcodeproj](../ntfy-tray.xcodeproj) in Xcode, select the `ntfy-tray` scheme, and run it on **My Mac**.

For the smoothest Keychain behavior during normal Xcode development, select your personal development team in the target’s Signing & Capabilities settings. This is separate from release packaging: local and GitHub releases use ad-hoc signing and do not require a Developer ID.

## Verify changes

Run the focused macOS tests from the project root:

```zsh
xcodebuild -quiet \
  -project ntfy-tray.xcodeproj \
  -scheme ntfy-tray \
  -destination 'platform=macOS,arch=arm64' \
  -only-testing:ntfy-trayTests \
  test \
  ARCHS=arm64 \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY=- \
  DEVELOPMENT_TEAM=
```

Also run:

```zsh
git diff --check
```

## Package a local release

Create an ad-hoc-signed DMG with:

```zsh
./scripts/build_dmg.sh
```

The app and DMG are created under `build/Release/`. Build output is ignored by Git.

## Publish a release

After pushing the repository, push an annotated `v*` tag. GitHub Actions runs the test suite, packages an ad-hoc DMG, creates a GitHub Release, and writes release notes from the commits since the previous tag.
