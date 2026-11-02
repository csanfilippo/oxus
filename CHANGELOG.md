# Changelog

All notable changes to oxus are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-11-02

### Added

- `spotlight_query` tool: runs a raw Spotlight query and returns the paths of matching files, in Spotlight's order.
- `search` tool: finds files by `name_contains` (ignoring case and diacritics), `kind` (`image`, `movie`, `audio`, `pdf`, `folder`, `application`) and `folder` (an absolute path, `~`, or a path starting with `~/`), or any combination of them, without Spotlight query syntax.
- Both tools take an optional `limit`, default 25, capped at 100.
- Both tools return `{"paths": [...]}` as structured content, described by an `outputSchema`, and as JSON in a single text block.
- A `search` `folder` that does not exist, is a file, is a package, or cannot be read returns an error result naming the path and the fix, instead of an empty list.
- A `search` `folder` denied by macOS privacy protection names the Privacy & Security setting to change, and one lacking read permission says so.
- A `search` whose `folder` contains `~/Downloads`, `~/Documents` or `~/Desktop`, a `search` without a `folder`, and every `spotlight_query` list in `unreadableFolders` those of the three folders macOS privacy protection denies, each with the setting to change, since Spotlight silently leaves out their files.

[Unreleased]: https://github.com/csanfilippo/oxus/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/csanfilippo/oxus/releases/tag/v0.1.0
