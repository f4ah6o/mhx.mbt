# Define swap engine behavior as low-level DOM primitives

Created: 2026-05-05
Model: N/A

## Summary

Define mhx swap behavior as a stable low-level DOM primitive contract.

## Motivation

DOM replacement is one of the core responsibilities of mhx. Applications should be able to rely on precise target resolution, swap behavior, lifecycle events, and error handling.

## Scope

Specify behavior for:

- `innerHTML`
- `outerHTML`
- `beforebegin`
- `afterbegin`
- `beforeend`
- `afterend`
- `delete`
- `none`

Also define:

- target resolution
- missing target behavior
- script handling policy
- focus preservation policy, if supported
- lifecycle hooks around swap

Suggested lifecycle hooks:

- `mhx:beforeRequest`
- `mhx:afterRequest`
- `mhx:beforeSwap`
- `mhx:afterSwap`
- `mhx:error`

## Acceptance criteria

- `docs/swap-contract.md` exists
- each swap strategy has DOM fixture tests
- missing target behavior is explicit
- `mx-swap="none"` behavior is documented
- lifecycle events are documented and tested
- swap behavior does not depend on application framework assumptions

## Non-goals

- no virtual DOM abstraction
- no template engine coupling
- no framework-specific lifecycle
