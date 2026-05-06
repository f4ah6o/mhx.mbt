# Stabilize mx-* attribute contract

Created: 2026-05-05
Model: N/A

## Summary

Stabilize the public `mx-*` attribute contract for mhx as a low-level hypermedia runtime.

## Motivation

mhx should be usable as a small, deterministic browser primitive. For that, supported attributes need to be specified as a contract, not only described as examples.

## Scope

Document supported attributes:

- `mx-get`
- `mx-post`
- `mx-put`
- `mx-patch`
- `mx-delete`
- `mx-trigger`
- `mx-target`
- `mx-swap`
- `mx-sync`
- `mx-vals`

Define:

- default values
- invalid combinations
- precedence when multiple request attributes exist
- parse / validation behavior
- future compatibility policy for new attributes

## Acceptance criteria

- `docs/attribute-contract.md` exists
- all supported attributes have normative semantics
- invalid combinations are documented
- defaults are documented
- parser / validator tests assert the contract
- README links to the contract document

## Non-goals

- no application framework integration
- no server-side routing convention
- no template engine coupling
