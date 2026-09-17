# ntfy-tray contributor guide

## Platform and architecture

- Target macOS 26.5+ with Swift 6 strict concurrency and default MainActor isolation.
- Build native SwiftUI and Apple frameworks only; do not add third-party dependencies without approval.
- Keep one primary type per Swift file and organize files by feature.
- Use `@Observable` state owned by SwiftUI with `@State`; isolate networking and other mutable background work in actors.
- Keep view bodies declarative. Put business logic in models, repositories, or services rather than views.

## Data and security

- Persist non-sensitive user data with SwiftData. Store tokens and other credentials only in Keychain.
- Never log, commit, or place credentials in `UserDefaults`, SwiftData, previews, fixtures, or screenshots.
- Accept only HTTPS ntfy servers. Do not add App Transport Security exceptions or certificate-bypass behavior.

## User experience

- Follow macOS Human Interface Guidelines: semantic system colors, native controls, concise copy, keyboard-accessible actions, and meaningful VoiceOver labels.
- Respect accessibility settings, Dynamic Type, Reduce Motion, and light/dark appearances.
- Prefer SF Symbols for product icons and use asset-catalog symbols via generated APIs where available.

## Quality and Git

- Add focused Swift Testing coverage for new core behavior. Avoid UI tests unless unit tests cannot cover the behavior.
- Before committing, run the macOS build/tests and `git diff --check`.
- Do not commit Xcode user data, DerivedData, build products, or generated local state.
- Keep commits small and imperative (`feat:`, `fix:`, `test:`, `chore:`); never mix unrelated changes.
