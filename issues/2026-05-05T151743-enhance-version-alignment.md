# Align runtime, MoonBit package, npm package, and docs versions

Created: 2026-05-05
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
