# Clarify mhx-spec / runtime / npm responsibility boundaries

Created: 2026-05-05
Completed: 2026-05-11
Model: N/A

## Summary

Clarify the boundary between specification/parser code, browser runtime code, and npm distribution code.

## Motivation

mhx can become more reusable if its core specification layer is independent from DOM, network, and packaging concerns. This allows parser tests, linters, static analyzers, and generators to depend on the spec without pulling in the browser runtime.

## Proposed layers

### 1. mhx-spec

Responsible for:

- attribute names
- trigger AST
- parser
- selector AST, if applicable
- swap enum
- parse / validation error codes

Should not depend on:

- DOM
- FFI
- network
- timers

### 2. mhx-runtime

Responsible for:

- DOM event delegation
- request execution
- queue / sync behavior
- swap execution
- lifecycle events

### 3. mhx-npm

Responsible for:

- bundled browser runtime
- ESM / UMD packaging
- CDN usage
- package smoke tests

## Acceptance criteria

- responsibility boundaries are documented
- runtime depends on spec, not the reverse
- parser tests run without browser-like environment
- runtime tests can use parsed AST fixtures
- README links to the architecture boundary document

## Non-goals

- no large rewrite required in one step
- no application framework integration
- no papyr-specific behavior

## 解決方法

- `docs/architecture.md` に `mhx-spec`、`mhx` runtime、npm/browser distribution の owns / does not own を明確化した。
- parser tests が browser-like globals なしで動く境界として `src/event/trigger_golden_test.mbt` を明記した。
- runtime は parsed AST fixtures を消費できるが、parser を DOM / fetch / timer / FFI に依存させない dependency direction を明文化した。
- npm package は root export の runtime surface だけを stable API とし、parser internals を npm subpath として公開しない方針を verification map に追加した。
- `npm/check-version-contract.mjs` に README architecture link と architecture boundary required sections の検査を追加した。
