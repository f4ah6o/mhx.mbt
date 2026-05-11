# Stabilize trigger DSL spec and golden tests

Created: 2026-05-05
Completed: 2026-05-11
Model: N/A

## Summary

Stabilize `mx-trigger` as an independent trigger DSL specification with parser golden tests.

## Motivation

The trigger DSL is one of the most important low-level contracts in mhx. It should be testable without DOM, network, or browser runtime dependencies.

## Scope

Add `docs/trigger-spec.md` covering:

- event names
- custom lifecycle events such as `load`, `revealed`, `intersect`
- filter syntax
- modifier syntax
- modifier values
- queue modifiers
- parse error behavior

Example expressions:

- `click`
- `click once`
- `input changed debounce:300ms`
- `click[ctrlKey] delay:500ms`
- `submit prevent queue:last`
- `intersect once`

## Acceptance criteria

- every supported trigger expression has a parse fixture
- representative invalid expressions have error fixtures
- parser output is deterministic
- parse errors include input, position, and reason or expected token
- parser tests run without DOM / network dependencies
- README links to the trigger spec

## Non-goals

- no browser event implementation changes required in this issue
- no framework integration

## 解決方法

`docs/trigger-spec.md` を更新し、`mx-trigger` を DOM / network に依存しない独立した DSL として整理した。event name、`load` / `revealed` / `intersect` の lifecycle event、filter、modifier、duration、selector、queue modifier、parse output、parse error behavior を現在の parser 実装に合わせて明文化した。

`src/event/trigger_golden_test.mbt` を追加し、issue の対象例である `click`、`click once`、`input changed debounce:300ms`、`click[ctrlKey] delay:500ms`、`submit prevent queue:last`、`intersect once` に加えて、lifecycle event、selector modifier、queue mode、multiple trigger の golden fixture を追加した。fixture は `mhx-spec/parser` の公開 API だけを使い、DOM / network に依存しない。

invalid expression の fixture として、missing colon、invalid duration、invalid queue mode、unclosed filter、missing event name を追加した。各 fixture は input と `ParseError` を組にして inspect し、position と expected token または invalid value が安定して確認できるようにした。

README の trigger spec へのリンク説明を補強し、queue modifier の例を実装が受け付ける `queue:last` 形式に直した。
