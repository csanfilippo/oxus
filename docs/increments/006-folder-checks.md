# Increment 6 — Folder checks

**Status:** Done (2026-10-31), split from increment 5.

## Goal

Tell the model when the `folder` of a `search` cannot be searched, so it can correct itself. Spotlight returns no paths and no error for a scope that does not exist, is a file, is a package, or cannot be read (checked on 2026-10-25), so after increment 5 the model reports "no files" as fact.

## Contract

- A `folder` that does not exist, is a file, or is a package (e.g. an `.app` bundle) returns a result with `isError: true` naming the path, which of the three it is, and the fix (correct the path, search the parent folder, search elsewhere), so the model can correct itself.
- A `folder` that cannot be read returns a result with `isError: true` naming the path and the reason macOS gives as its POSIX description (e.g. `Permission denied`, `Operation not permitted`), never an empty success.
- Errors name the expanded path the adapter searches, e.g. `/Users/me/Dowloads` for `~/Dowloads`.
- Output and error messages of increment 5 stay unchanged.

## Out of scope

Telling the user what to grant for a folder protected by TCC, protected subfolders inside a readable scope, and unscoped searches losing results are increment 7. A folder inside a package (e.g. `Calculator.app/Contents`): only the scope folder itself is checked, so it still returns no paths and no error (decided on 2026-10-29). Detecting folders Spotlight does not index (see increment 5's risks).

## Design

- **`LocalFileSystem` lists the folder before searching:** Spotlight returns no paths and no error for a scope that does not exist, is a file, is a package, or cannot be read (checked on 2026-10-25), which the model would report as "no files". One listing of the folder tells these apart, because its error says which case applies, so no order of checks has to be defined:

  | `folder` | Listing (checked on 2026-10-25) | `FolderError` case | Fix |
  |---|---|---|---|
  | does not exist | Cocoa 260 | not found | correct the path |
  | is a file | underlying POSIX `ENOTDIR` | not a folder | use the parent folder |
  | cannot be read | Cocoa 257 with `EACCES` for file permissions (a `chmod 000` folder); "Operation not permitted" (`EPERM`) for TCC (seen from `ls`) | cannot read | depends on the reason, which the message carries |
  | is a package | succeeds | package | search elsewhere |

  A package lists fine but Spotlight indexes nothing inside it (0 indexed items in `.app`, `.xcodeproj`, `.photoslibrary`, `.bundle` and `.playground` packages, checked with `kMDItemDisplayName == "*"`; a bare `*` on `kMDItemFSName` matches nothing anywhere), so a successful listing is followed by a package check. The package check reads the resolved path: the listing follows symlinks, but `isPackageKey` reads the link itself, so a symlink to `Calculator.app` reports `isPackage` false (checked on 2026-10-25) and would pass as a folder that returns no paths. The listing is file-system I/O, so it stays out of the domain type, behind the `FileSystem` port that `search` calls right before Spotlight (moved out of `CoreServicesSpotlight` on 2026-10-31, so the Spotlight adapter only queries). A fake `FileSystem` must be able to throw each case, and each needs an adapter test: a path that does not exist, `/System/Library/CoreServices/SystemVersion.plist`, a `chmod 000` folder, and `/System/Applications/Calculator.app` directly and through a symlink.

## Open decisions

None. Decided on 2026-10-29: messages carry the fix, name the expanded path, and give the POSIX description as the reason; a folder inside a package is out of scope.

## Test list

`docs/tests/increment-6-test-list.txt` (written on 2026-10-29). Acceptance tests chosen on 2026-10-25: a folder that does not exist, and `/System/Applications/Calculator.app` as a package.

## Risks

- The "cannot read" message says only what macOS reports, not what to grant; increment 7 makes it precise.
- The folder is listed on every scoped search, which costs time in proportion to its entries. Measured on 2026-10-25: listing `~/Downloads` (191 entries) took 0.1 ms.
