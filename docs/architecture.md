# architecture boundaries

`mhx` is intentionally split into three layers.

## 1. `mhx-spec`

Owns:

- trigger grammar and AST
- swap/sync specification values
- parser positions and parse errors

Does **not** own:

- DOM execution
- network scheduling implementation
- browser bundle packaging

## 2. `mhx` runtime

Owns:

- DOM event delegation
- request scheduling and queue semantics
- fetch bridge usage
- DOM swap execution
- lifecycle hook dispatch
- structured runtime errors

## 3. npm/browser distribution

Owns:

- ESM / UMD packaging
- published file list
- smoke tests for consumer-facing exports
- README.npm.md consumer contract

## Dependency direction

The runtime depends on `mhx-spec`, never the reverse.
The npm bundle depends on the runtime surface, not on parser internals.
