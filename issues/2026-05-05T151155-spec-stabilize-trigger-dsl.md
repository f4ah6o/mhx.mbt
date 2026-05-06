# Stabilize trigger DSL spec and golden tests

Created: 2026-05-05
Model: N/A

## Summary

Stabilize `mx-trigger` as an independent trigger DSL specification with parser golden tests.

## Motivation

The trigger DSL is one of the most important low-level contracts in mhx. It should be testable without DOM, network, or browser runtime dependencies.

## Scope

Add `docs/trigger-spec.md` covering:

- event names
- custom lifecycle events such as `load`, `revealed`, `intersect`
- filter syntax
- modifier syntax
- modifier values
- queue modifiers
- parse error behavior

Example expressions:

- `click`
- `click once`
- `input changed debounce:300ms`
- `click[ctrlKey] delay:500ms`
- `submit prevent queue:last`
- `intersect once`

## Acceptance criteria

- every supported trigger expression has a parse fixture
- representative invalid expressions have error fixtures
- parser output is deterministic
- parse errors include input, position, and reason or expected token
- parser tests run without DOM / network dependencies
- README links to the trigger spec

## Non-goals

- no browser event implementation changes required in this issue
- no framework integration
