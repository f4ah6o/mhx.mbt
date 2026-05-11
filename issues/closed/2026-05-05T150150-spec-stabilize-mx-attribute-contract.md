# Stabilize mx-* attribute contract

Created: 2026-05-05
Completed: 2026-05-11
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

## 解決方法

`docs/attribute-contract.md` を更新し、supported `mx-*` attributes の規範的な意味、既定値、無効な組み合わせ、request attribute の優先順位なしの扱い、target / trigger / sync / `mx-vals` の precedence、parse / validation behavior、future compatibility policy を明文化した。

README の Contracts and boundaries から attribute contract が規範文書であることを分かるようにリンク文言を補足した。

既存実装の parser / validator contract に合わせて、`mx-vals` が form field より後ろに merge されることと、`mx-target` の不完全な extended selector が `MHX_PARSE_INVALID_SELECTOR` として拒否されることをテストで確認した。
