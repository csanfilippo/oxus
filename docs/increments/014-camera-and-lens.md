# Increment 14 — `search` by camera and lens

**Status:** Planned

## Goal

Let `search` find photos and videos by the camera and lens that took them, so a request like "the RAW files I shot with the 16-80 on the X-T4" becomes `search(camera: "X-T4", lens: "16-80")`, without the model knowing Spotlight's attribute names.

## Contract

- Adds `camera` (string, optional) to `search`: each word must appear in the file's camera make or model, ignoring case and diacritics. `"X-T4"`, `"Fujifilm"` and `"Fujifilm X-T4"` all match a file with make `FUJIFILM` and model `X-T4`.
- Adds `lens` (string, optional) to `search`: each word must appear in the file's lens model, ignoring case and diacritics. `"16-80"` and `"XF 16-80"` both match `XF16-80mmF4 R OIS WR`.
- `camera` and `lens` count as filters: at least one of `name_contains`, `kind`, `folder`, `camera` and `lens` is required, and filters in the same call are combined with AND.
- A blank or non-string `camera` or `lens` is an error result, like a blank `name_contains`.
- Files without camera or lens metadata never match a `camera` or `lens` filter.
- The result, `limit`, `truncated`, `unreadableFolders` and every `folder` error are unchanged. `spotlight_query` is unchanged.

## Out of scope

- Finding photos by place (`kMDItemLatitude`, `kMDItemLongitude`): a later increment, once a photo with GPS data has been checked with `mdls`.
- Place names (`kMDItemCity`, `kMDItemCountry`), which are set only by hand, and turning a place name into coordinates, which would need the network.
- Shot settings: focal length, aperture, ISO, shutter speed.
- A date-taken range.
- Returning the camera, lens or any other metadata next to each path.
- Photos inside the Apple Photos library, which is a package: Spotlight indexes nothing inside packages (see increment 6).

## Design

- **Spotlight attributes:** `camera` matches `kMDItemAcquisitionMake` and `kMDItemAcquisitionModel`, and `lens` matches `kMDItemLensModel`. Checked by the user with `mdls` on a Fujifilm X-T4 RAF on 2026-11-19: make `FUJIFILM`, model `X-T4`, lens `XF16-80mmF4 R OIS WR`. The same day, `mdfind 'kMDItemLensModel == "*"'` returned JPEGs and RAFs from several folders, so the attribute can be queried and is not only read by `mdls`. It also returned a JPEG bundled with a web project, so camera metadata is not limited to the user's own photos.
- **Each word is its own clause.** `camera: "Fujifilm X-T4"` compiles to `(make contains "Fujifilm" || model contains "Fujifilm") && (make contains "X-T4" || model contains "X-T4")`, each with `cd`. A model usually names the brand and the model together, and Spotlight cannot match across two attributes. Lens names are written with and without spaces (`XF16-80mm`, `XF 16-80mm`), so whole-string matching would miss them.
- **Two new argument types**, `CameraArgument` and `LensArgument`, each a `NonEmptyStringArgument` with its own domain type, added to `docs/design/tool-arguments.md` and its diagram.
- **`SearchCriteria`** takes `camera` and `lens`, compiles their clauses next to the name and kind clauses, and lists all five filters in its `noFilters` message. The match-all query for a folder alone is unchanged.
- The `Spotlight` port and `CoreServicesSpotlight` are unchanged: the new clauses are ordinary query text.
- Adding optional arguments changes no existing result, so this ships as a minor release under `docs/releasing.md`.

## Manual check

Point a client at a release build of this increment. Ask for photos taken with a camera you own, then with one of its lenses, then both with `kind: image`, and compare with `mdfind`.

## Open decisions

- **Word matching, or the whole string as one `contains`.** Recommended: words, for the reasons above. The cost is that `camera` and `lens` behave differently from `name_contains`, and the argument descriptions must say so.
- **How acceptance and adapter tests get a file with camera metadata.** No always-indexed system file is known to carry `kMDItemAcquisitionModel`. Options: find one under `/System` with `mdfind 'kMDItemAcquisitionModel == "*"'`; or check in a small JPEG fixture with EXIF make, model and lens, copy it to a temporary folder, index it with `mdimport`, and wait for Spotlight to return it.
- **Whether `camera` and `lens` imply `kind: image`.** Recommended: no. Cameras also record movies, and `kind` already narrows to images.

## Risks

- **Indexing delay in tests.** A fixture written at test time may not be searchable at once; a test that waits needs a bound, or it hangs or flakes.
- **RAW support varies by camera.** Spotlight extracts metadata only from RAW formats macOS can read, so a new camera's files may have no make, model or lens until macOS supports it.
- **Lens names vary by maker.** Some cameras write only a focal range, or nothing for adapted manual lenses, so `lens` can miss files that `camera` finds.

## Test list

[`014-camera-and-lens.test-list.txt`](014-camera-and-lens.test-list.txt)
