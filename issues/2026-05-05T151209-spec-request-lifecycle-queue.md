# Specify request lifecycle and queue semantics

Created: 2026-05-05
Model: N/A

## Summary

Define the request lifecycle and queue semantics as a deterministic low-level runtime contract.

## Motivation

`delay`, `throttle`, `debounce`, `queue`, and `sync` can interact in subtle ways. mhx should provide deterministic behavior that applications and higher-level libraries can rely on.

## Proposed lifecycle states

- `idle`
- `scheduled`
- `in_flight`
- `swapping`
- `completed`
- `failed`
- `aborted`

## Queue modes

Define behavior for:

- `drop`
- `replace`
- `first`
- `last`
- `all`

## Acceptance criteria

- `docs/request-lifecycle.md` exists
- lifecycle state transitions are documented
- queue behavior is covered by tests
- abort behavior is explicit
- repeated trigger behavior is deterministic
- network failure does not leave stale queue state
- lifecycle events are stable and documented

## Non-goals

- no application-specific loading UI
- no framework-specific state integration
