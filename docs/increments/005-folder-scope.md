# Increment 5 — Folder scope

**Status:** Done (2026-10-27). Split on 2026-10-25: checking the folder before searching moved to increment 6.

## Goal

Let `search` look only inside a given folder, so a request like "find the PDFs in my Downloads" becomes `search(kind: "pdf", folder: "~/Downloads")`. Without a scope every search runs over the whole index, so results are crowded with caches, `Library` and system bundles, and the limit of 25 paths by default (100 at most) cuts off the files the user actually wants.

## Contract

- Adds `folder` (string, optional) to `search`: the folder to search in, including its subfolders.
- A `folder` is an absolute path, `~` alone, or a path starting with `~/`; the `~` is expanded to the user's home. Anything else, such as a relative path (`Downloads`) or another `~` form (`~alice/Downloads`), returns a result with `isError: true` saying which forms are accepted.
- `folder` is combined with the other filters by AND.
- The folder itself is never a result: `folder` means inside the folder.
- A blank or non-string `folder` returns a result with `isError: true`, as for `name_contains`.
- `folder` alone is a valid search: `search(folder: "~/Downloads")` returns the files in Downloads. The "at least one filter" error and the tool description name `folder` alongside `name_contains` and `kind`.
- Output, limits and error messages of existing arguments stay unchanged, apart from the "at least one filter" message.
- The tool description states that the scope includes subfolders, which forms `folder` accepts, and that files Spotlight does not index cannot be found.

## Out of scope

Several folders in one call, excluding folders, limiting depth (e.g. top level only), scoping `spotlight_query`, Spotlight's predefined scopes (home, computer, network), pagination, sorting (results keep Spotlight's order, which is neither newest first nor alphabetical), detecting folders Spotlight does not index. Reporting a folder that does not exist, is a file, is a package or cannot be read is increment 6. macOS privacy protection (TCC) beyond that: telling the user what to grant, protected subfolders inside a readable scope, and unscoped searches losing results are increment 7.

## Design

- **Spotlight mechanism:** `MDQuerySetSearchScope` restricts an `MDQuery` to a list of folders and includes their subfolders; it is what `mdfind -onlyin` uses. The scope is set on the query, not written in the query string, so it cannot be expressed through the current `Spotlight` port, which takes only a query string and a limit.
- **No scope in the query string:** a `kMDItemPath` predicate is not rejected as malformed but matches nothing, with or without wildcards (checked with `mdfind` on 2026-10-25), so a raw `spotlight_query` cannot scope itself either.
- **The port takes the folder:** `Spotlight.search` gains an optional folder alongside the query and the limit; no folder means the whole index, which is what `spotlight_query` passes. The folder is a domain type, `Folder`, not a `String`: it accepts only an absolute path, so the adapter can never receive a relative path or an unexpanded `~`. `FolderArgument` builds it from the `folder` argument, so path rules live in `OxusServer`, and the adapter turns the folder into `MDQuerySetSearchScope`.
- **`~` is expanded when the `folder` argument is read:** models write "my Downloads" as `~/Downloads`, and not every host tells the model the user's home path. `FolderArgument` expands `~` alone or followed by `/` to a home folder it is given, never read from the environment, so tests can pass a fixed one (e.g. `/Users/test`, expecting `/Users/test/Downloads`) and pass on any machine. The composition root (`oxus`) supplies the server's home, which is the user's home because a stdio server runs as the client's user (unless a sandboxed host redirects `HOME`). The adapter only sees the expanded path, so its errors (increment 6) name it, e.g. `/Users/feanor/Downloadz` for `~/Downloadz`. Relative paths and other `~` forms such as `~alice` are rejected before any I/O: the server's working directory means nothing to the client, models have no need for another user's home, and it is rarely readable. Expansion moved out of `Folder` on 2026-10-31: it belongs to reading the client's input, and keeping it out leaves `Folder` with the single rule that its path is absolute, so the adapter tests build one with no home.
- **A folder alone needs a match-all query:** with neither `name_contains` nor `kind`, the query string must still match every file. `kMDItemFSName == "*"` matches nothing anywhere, but `kMDItemDisplayName == "*"` does (65 paths under `/System/Applications`, checked with `mdfind` on 2026-10-25); an adapter test should confirm it returns every indexed file in a scope.

## Open decisions

None.

## Test list

`docs/tests/increment-5-test-list.txt`

## Risks

- A folder that does not exist, is a file, is a package or cannot be read returns no paths and no error until increment 6, which the model would report as "no files". `~/Downloads`, `~/Desktop` and `~/Documents` are protected by TCC, and without access Spotlight drops their files silently (measurements in increment 7).
- A folder Spotlight does not index passes every check of increment 6 and returns no paths with no error, which the model would report as "no files". Checked on 2026-10-25: a folder under `/private/tmp` (18 files on disk) and a `.noindex` folder in the home (1 file) both returned 0 paths. Folders excluded in System Settings › Spotlight › Privacy and volumes with indexing turned off probably behave the same (not checked). There is no simple, reliable way to ask Spotlight whether a folder is indexed, so the tool description warns instead.
- Adapter and acceptance tests need a scope that is always indexed and not protected by TCC, e.g. `/System/Applications` (Finder is in `/System/Library/CoreServices`, so it is outside that scope and can prove that the scope excludes files). `SpySpotlight` assumes the scope includes subfolders, excludes files outside it and excludes the folder itself, so adapter tests must cover all three, e.g. `Terminal.app` is found under `/System/Applications` (it is in `Utilities`), `Finder.app` is not, and a search for `Utilities` under `/Applications/Utilities` returns no paths (checked with `mdfind -onlyin` and `MDQuerySetSearchScope` on 2026-10-25). The folder test cannot use `/System/Applications/Utilities`: Spotlight does not index it (`mdls` shows no name, checked on 2026-10-27), so a search could never return it, scope or not. `/Applications/Utilities` is indexed, found by a whole-index `kMDItemFSName == "Utilities"` search, and missing from a search scoped to itself.
- Paths with symlinks (e.g. `/tmp` → `/private/tmp`) may not match how Spotlight stores paths. Checked on 2026-10-25 with `mdfind -onlyin` and with `MDQuerySetSearchScope` directly: a scope through a symlink to `/System/Applications` returns the same paths as the real folder, so a symlinked scope behaves like the folder it points to. An adapter test with a symlinked scope keeps this verified.
