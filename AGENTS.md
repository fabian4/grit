# Repository Guidelines

## Project Structure & Module Organization
This repo contains a macOS SwiftUI app backed by a Rust core accessed via UniFFI.

- `app/`: SwiftPM app entry point and UI code.
- `app/Sources/App/`: `GritApp` and top-level views.
- `app/Sources/ViewModels/`: UI state and async actions.
- `app/Sources/Services/`: Swift-facing client and UniFFI bindings.
- `app/Sources/Services/Generated/`: generated Swift bindings (do not edit).
- `crates/core/`: Rust core logic and UniFFI UDL.
- `crates/core/src/`: Rust sources (`git_runner.rs`, `repo_service.rs`).
- `scripts/`: developer scripts (binding generation).

No tests or assets are defined yet.

## Build, Test, and Development Commands
- `make gen`: Generate Swift bindings into `app/Sources/Services/Generated/`.
- `make build-core`: Build the Rust core crate (`crates/core`).
- `make run`: Build the macOS app with `xcodebuild`.

There are currently no automated test commands.

## Coding Style & Naming Conventions
- Swift: 4-space indentation, UpperCamelCase for types, lowerCamelCase for methods and properties.
- Rust: follow `rustfmt` defaults, snake_case for functions and modules, UpperCamelCase for types.
- Keep UI code in `app/` and core logic in `crates/core/`. Do not edit generated bindings.

## Testing Guidelines
No testing framework is configured yet. If adding tests, keep Swift tests under `app/Tests/` (SwiftPM default) and Rust tests alongside modules in `crates/core/src/`.

## Commit & Pull Request Guidelines
This repository has no commit history yet, so there are no established commit message conventions. Use clear, imperative summaries (e.g., "Add repo open flow").

For PRs, include:
- A short description of user-visible changes.
- Build/run steps if they changed.
- Screenshots for UI changes (macOS window).

## Agent-Specific Notes
- Generate bindings via `scripts/gen-bindings.sh` rather than editing `Generated/` manually.
- Git operations in Rust should shell out to system `git` (no libgit2).
- Agent rule: never run git commands in this repository.

## Peekaboo UI Validation Workflow
Use Peekaboo for visual verification when iterating on macOS UI.

- Preconditions:
- `peekaboo` is installed (`peekaboo --version`).
- Accessibility and Screen Recording permissions are granted (`peekaboo permissions --json`).
- App is launched from local build output to avoid Dock/app-cache confusion:
  - `./app/.build/debug/Grit.app/Contents/MacOS/Grit`

- Recommended capture flow:
- Launch local app and keep PID:
  - `./app/.build/debug/Grit.app/Contents/MacOS/Grit >/tmp/grit-ui.log 2>&1 &`
  - `APP_PID=$!`
- List windows by PID and get bounds:
  - `peekaboo window list --pid "$APP_PID" --json > /tmp/grit-ui-window.json`
- Capture using native `screencapture -R` from bounds in JSON.

- Notes:
- `peekaboo image --mode window` may capture the wrong surface on multi-display setups.
- `peekaboo image --window-id ...` can return `WINDOW_NOT_FOUND` in some versions.
- Prefer PID-scoped window listing + rectangle capture for deterministic results.
- For before/after comparisons, save separate files (for example, `/tmp/grit-ui-before.png` and `/tmp/grit-ui-after.png`) and compare hashes or images.
