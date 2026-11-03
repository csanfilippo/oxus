# Increment 11 — Concurrent queries

**Status:** In progress

## Goal

Stop concurrent tool calls from hanging the server. On a Mac with 10 CPUs, 9 concurrent `spotlight_query` calls all reply and 10 get no reply at all, with no error, including the calls that started first.

## Contract

- Every concurrent `spotlight_query` and `search` call gets its own reply, however many are in flight, including more than the Mac has CPUs.
- Results and errors are unchanged, so a call's reply depends only on its own arguments.
- The `Spotlight` port is unchanged.

## Out of scope

- Running queries in parallel: they run one at a time.
- A timeout on a query, and cancelling a running one.
- Asynchronous `MDQuery` with notifications.

## Design

- `CoreServicesSpotlight.search` is `async`, but `MDQueryExecute` in synchronous mode blocks its cooperative thread in `_pthread_cond_wait` until the query ends. With every cooperative thread blocked this way, no query ends.
- The fix lives only in `MacOSAdapters`: `CoreServicesSpotlight` stays a struct, and a global actor isolates its `search`, so at most one query runs in the process, however many instances exist.
- A comment on the global actor explains why it exists: the reason is not visible in the code, and removing the isolation brings the hang back.
- This is a patch release: no tool's arguments or results change.

## Manual check

Pipe more concurrent `spotlight_query` calls than the Mac has CPUs into the built binary, as in `CLAUDE.md`, and see one reply per call.

## Open decisions

None.

## Decisions

- **A global actor, not a serial queue** (2026-11-04): an actor and a serial queue both passed at 200 concurrent tasks, with about 5 s for a fast query behind a slow one, because both run one query at a time. An actor is the smaller change and keeps typed throws. It accepts one cooperative thread blocked for the length of a query, against [SE-0296](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0296-async-await.md). A serial `DispatchQueue` keeps the blocking out of `async` code, but needs a continuation and carries `SpotlightError` through a `Result`.
- **A global actor, not an instance actor** (2026-11-04): an instance actor only serialises itself, and the tests create one `CoreServicesSpotlight` per test, 21 in all. 13 instance actors hung in a scratch program, while a global actor passed with 200 instances. The rule is process-wide, so the isolation is too. It also needs no `.serialized` suites and no rule about how many instances exist.
- **A regression hangs** (2026-11-04): the tests stay plain. `.timeLimit(.minutes(1))` did not stop a hung test, which was still running at 100 s with no failure recorded, and a watchdog is not worth its infrastructure for tests that only run locally. CI skips them, so `swift test` before a release is what catches this.
- **Measurements** (2026-11-04), on a Mac with 10 CPUs. The real binary replied to 1, 5 and 9 concurrent calls, and to none of 10 or 12 within a 10-second window. On the cooperative pool, 10 or more concurrent queries hung with any query tested; one mix also timed out at 9, not investigated. 12 plain threads running the same queries did not hang. One query took 0.05 s alone and 2.8 s while 9 other tasks blocked pool threads for 3 s.
- **Not a concurrent queue** (2026-11-04): it passed at 50 tasks, and gave no result within 12 s from 63 upwards. It moves the limit instead of removing it.

## Test list

[`011-concurrent-queries.test-list.txt`](011-concurrent-queries.test-list.txt)

## Risks

- **Cause not understood.** Metadata.framework is closed source. A free cooperative thread is not literally what a query needs: with the pool forced to one thread by `LIBDISPATCH_COOPERATIVE_POOL_STRICT=1`, blocking queries finish. Blocked threads may be using up a Dispatch thread budget Spotlight also needs, which is unproven. The fix rests on measurements, so the regression tests carry the weight.
- **A regression hangs instead of failing.** Accepted, see Decisions. It shows up only locally, as a `swift test` that never ends.
- **Threshold on other Macs.** It should equal the CPU count, but it was measured on one Mac only.
- **Shipped releases.** The adapter has the same code in 0.2.0, which was not run for this. Whether clients send enough calls at once is also unchecked.
- **Slow queries delay others.** A fast query waits about 5 s behind a `kMDItemContentTypeTree == "public.item"` query.
