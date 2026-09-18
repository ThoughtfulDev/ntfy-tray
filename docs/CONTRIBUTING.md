# Contributing to ntfy-tray

[← Back to the README](../README.md)

Thank you for helping make ntfy-tray a better macOS companion.

## Before you start

Keep changes focused and discuss substantial product or architectural changes before investing in a large implementation. A short issue or pull request description that explains the user-facing goal is usually enough.

## Working principles

- Build with native Apple frameworks and keep the experience at home on macOS.
- Keep credentials out of source control, logs, fixtures, and screenshots.
- Accept only HTTPS ntfy servers.
- Prefer accessible, keyboard-friendly native controls and semantic system colors.
- Add focused tests for new behavior; avoid UI tests unless core behavior cannot be tested another way.

## Sending a change

1. Create a focused branch from `main`.
2. Make the smallest cohesive change that solves the problem.
3. Run the checks in the [development guide](DEVELOPMENT.md).
4. Use an imperative conventional commit prefix such as `feat:`, `fix:`, `test:`, `docs:`, `ci:`, or `chore:`.
5. Open a pull request with a concise summary and verification notes.

## Review checklist

Before requesting review, make sure the change has no unrelated formatting, generated files, Xcode user data, or build products. Explain any visual change with a screenshot when it helps reviewers understand the result.
