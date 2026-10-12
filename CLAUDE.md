# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`oxus` is a Swift command-line tool built with Swift Package Manager and [swift-argument-parser](https://github.com/apple/swift-argument-parser). The repository is at the initial-template stage: a single executable target whose `@main` entry point is a `ParsableCommand` in `Sources/oxus/oxus.swift`.

## Commands

```sh
swift build                 # debug build
swift build -c release      # release build
swift run oxus [args]       # build and run the CLI
swift run oxus --help       # ArgumentParser-generated help
swift test                  # run tests (no test target exists yet)
swift test --filter <TestTarget>.<Suite>/<test>   # run a single test
```

## Toolchain and compiler settings

- `swift-tools-version: 6.4` — Swift 6 language mode, so strict concurrency checking is on.
- The `oxus` target enables the `ApproachableConcurrency` upcoming feature; keep it enabled on any new target so concurrency semantics stay uniform across the package.
- Dependency versions are pinned in `Package.resolved`, which is committed.

## Structure

- New CLI functionality is added as `ParsableCommand` types; subcommands are registered via `CommandConfiguration(subcommands:)` on the root `Oxus` command.
- There is no test target yet. When adding one, declare a `.testTarget` in `Package.swift` under `Tests/`. Because an `executableTarget` is awkward to import from tests, put domain logic in a separate library target that both the executable and the tests depend on, keeping the executable a thin CLI adapter.
