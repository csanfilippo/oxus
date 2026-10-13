# Increment 3 — `search` by kind

**Status:** Proposed

## Goal

Let `search` filter by kind of file, so a request like "find all the images whose name contains xyz" becomes `search(name_contains: "xyz", kind: "image")`.

## Contract

- Adds `kind` (string, optional) to `search`, advertised as an `enum`: `image`, `movie`, `audio`, `pdf`, `folder`, `application`.
- `name_contains` becomes optional; at least one filter is required.
- Filters present in the same call are combined with AND.

## Design

- **`Kind` enum** maps each kind to a content type matched on `kMDItemContentTypeTree` (e.g. `image` → `public.image`), so parent types match all subtypes (PNG, JPEG, HEIC…).
- The schema's `enum` is built from `Kind.allCases`, so the advertised kinds and the accepted kinds cannot drift apart.

## Open decisions

- The initial set of kinds.
- What a call with no filters returns: an error (recommended — an empty query would match everything) or the most recent files.
