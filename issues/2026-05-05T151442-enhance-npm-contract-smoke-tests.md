# Improve npm package consumer contract and smoke tests

Created: 2026-05-05
Model: N/A

## Summary

Improve the npm package contract for JavaScript consumers of mhx.

## Motivation

mhx is a MoonBit/Wasm library, but its browser runtime is consumed through JavaScript package formats. The npm package should be smoke-tested as a distributable artifact, not only as source code.

## Scope

Add or clarify:

- ESM import contract
- UMD script tag contract
- published file list
- `types` policy, or explicit note that TypeScript types are not provided
- `sideEffects` decision
- browser compatibility matrix
- CDN usage / integrity guidance
- minimal vanilla HTML example

## Acceptance criteria

- npm package can be smoke-tested after `npm pack` / equivalent
- ESM import smoke test exists
- UMD script tag smoke test exists
- published files are verified in CI
- README.npm.md documents the package contract
- package version and runtime version are checked or intentionally documented as separate

## Non-goals

- no framework-specific adapters
- no bundler-specific plugin requirement
