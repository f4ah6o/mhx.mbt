# Align runtime, MoonBit package, npm package, and docs versions

Created: 2026-05-05
Completed: 2026-05-11
Model: N/A

## Summary

Align or explicitly document versioning across the mhx runtime, MoonBit package, npm package, docs, and release tags.

## Motivation

Consumers need to know which runtime contract they are using. Version mismatch between runtime exports, package metadata, docs, and release tags can make debugging and compatibility checks difficult.

## Scope

Define versioning policy for:

- runtime `version` export
- MoonBit package version
- npm `package.json.version`
- README examples
- release tags

## Acceptance criteria

- one canonical runtime version source is defined, or separate version domains are explicitly documented
- tests or CI checks detect accidental version mismatch
- README examples reflect the intended versioning policy
- release checklist includes version consistency check

## Non-goals

- no requirement to use semantic versioning if date-based versioning is intentional
- no release automation required in this issue

## 解決方法

- `docs/versioning.md` に MoonBit package version と npm/runtime version の 2 domain policy を明文化し、npm release tag は `v<package.json.version>` とした。
- `docs/versioning.md` に release checklist を追加し、`pnpm verify:versions` と `pnpm build` を release 前の確認として固定した。
- `npm/check-version-contract.mjs` を拡張し、`moon.mod.json`、`src/lib.mbt`、MoonBit tests、README MoonBit install examples、README npm CDN examples、versioning policy document を検査するようにした。
- README npm contract が 2 つの version domain を説明し続けることを script で確認するようにした。
