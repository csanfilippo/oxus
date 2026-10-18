# Increment 3 — `search` by kind

**Status:** Done (2026-10-18)

## Goal

Let `search` filter by kind of file, so a request like "find all the images whose name contains xyz" becomes `search(name_contains: "xyz", kind: "image")`.

## Contract

- Adds `kind` (string, optional) to `search`, advertised as an `enum`: `image`, `movie`, `audio`, `pdf`, `folder`, `application`.
- `name_contains` becomes optional; at least one filter is required.
- Filters present in the same call are combined with AND.

## Design

- **`Kind` enum** maps each kind to a content type matched on `kMDItemContentTypeTree` (e.g. `image` → `public.image`), so parent types match all subtypes (PNG, JPEG, HEIC…).
- The schema's `enum` is built from `Kind.allCases`, so the advertised kinds and the accepted kinds cannot drift apart.

## Decisions

- **Initial kinds:** `image`, `movie`, `audio`, `pdf`, `folder`, `application`.
- **No filters is an error:** an empty query would match everything; the message says at least one of `name_contains` or `kind` is required.
- **Unknown or non-string `kind` is an error that lists the accepted kinds,** so the client's LLM can correct itself.
- **Kind values are exact and lowercase:** only advertised values are accepted.
- **A blank `name_contains` stays an error** even when `kind` is present: a filter that is present but blank is a client mistake.
- **Acceptance tests check both directions:** "finde" + `application` finds Finder, and "finde" + `folder` does not, which proves the kind clause reaches Spotlight and is combined with AND.

## Test list

`docs/tests/increment-3-test-list.txt`
