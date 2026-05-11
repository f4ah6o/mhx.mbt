# Architecture boundaries

`mhx` is intentionally split into three layers.

## 1. `mhx-spec`

Owns:

- supported attribute names and stable low-level syntax
- trigger grammar and AST
- selector AST values used by trigger `from:` and `target:` modifiers
- swap/sync specification values
- parser positions and parse errors
- parse-oriented error codes that runtime wrappers expose as `MHX_PARSE_*`

Does **not** own:

- DOM execution
- FFI bindings
- network scheduling implementation
- timers, event listeners, or MutationObserver wiring
- browser bundle packaging

Parser and AST tests must be able to run without browser-like globals. In this
repo, `src/event/trigger_golden_test.mbt` exercises `mhx-spec/parser` through
the runtime package dependency using string fixtures only.

## 2. `mhx` runtime

Owns:

- DOM event delegation
- trigger filter evaluation against browser event objects
- request scheduling and queue semantics
- fetch bridge usage
- DOM swap execution
- lifecycle hook dispatch
- structured runtime errors

Runtime code may depend on parsed `mhx-spec` AST values, but it must not make
the parser depend on DOM, fetch, timer, or FFI state. Runtime tests may use
parsed AST fixtures when checking scheduling, selector, or lifecycle behavior.

## 3. npm/browser distribution

Owns:

- ESM / UMD packaging
- published file list
- smoke tests for consumer-facing exports
- README.npm.md consumer contract
- CDN and Subresource Integrity usage examples
- package metadata such as `exports`, `files`, `sideEffects`, and absence of
  TypeScript declarations until they are published

## Dependency direction

The runtime depends on `mhx-spec`, never the reverse.
The npm bundle depends on the runtime surface, not on parser internals.

The stable npm surface is the package root export documented in
[`README.npm.md`](../README.npm.md) and [`ffi-boundary.md`](./ffi-boundary.md).
Distribution checks must verify package files and public exports without making
parser internals importable as npm subpaths.

## Verification map

| Boundary | Verification |
| --- | --- |
| spec parser does not require browser state | `src/event/trigger_golden_test.mbt` uses string fixtures and `mhx-spec/parser` |
| runtime consumes parsed AST values | runtime tests in `src/core`, `src/event`, and `src/network` exercise parsed trigger, selector, sync, and request behavior |
| npm package exposes only runtime surface | `npm/smoke/package-contract.test.mjs` checks ESM/UMD exports and package subpaths |
| package contents stay distribution-only | `npm/verify-package.mjs` checks the `npm pack --dry-run --json` file list |
| architecture docs stay linked | `npm/check-version-contract.mjs` checks README links and required boundary sections |
