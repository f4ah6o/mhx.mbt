# Improve npm package consumer contract and smoke tests

Created: 2026-05-05
Completed: 2026-05-11
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

## 解決方法

- `README.npm.md` に ESM / UMD contract、published files、TypeScript declaration 未提供、`sideEffects: true`、browser compatibility、CDN/SRI guidance、vanilla HTML example、version domain policy を明文化した。
- `npm/smoke/package-contract.test.mjs` で ESM / UMD の public surface、package subpath exports、published `files` field、`sideEffects`、`types` / `typings` absence を固定した。
- 既存の `npm/verify-package.mjs` が `npm pack --dry-run --json` で tarball file list を確認し、`pnpm build` 経由で CI から実行される package verification と smoke test の経路を維持した。
