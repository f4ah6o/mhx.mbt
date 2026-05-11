# Specify request lifecycle and queue semantics

Created: 2026-05-05
Completed: 2026-05-11
Model: N/A

## Summary

Define the request lifecycle and queue semantics as a deterministic low-level runtime contract.

## Motivation

`delay`, `throttle`, `debounce`, `queue`, and `sync` can interact in subtle ways. mhx should provide deterministic behavior that applications and higher-level libraries can rely on.

## Proposed lifecycle states

- `idle`
- `scheduled`
- `in_flight`
- `swapping`
- `completed`
- `failed`
- `aborted`

## Queue modes

Define behavior for:

- `drop`
- `replace`
- `first`
- `last`
- `all`

## Acceptance criteria

- `docs/request-lifecycle.md` exists
- lifecycle state transitions are documented
- queue behavior is covered by tests
- abort behavior is explicit
- repeated trigger behavior is deterministic
- network failure does not leave stale queue state
- lifecycle events are stable and documented

## Non-goals

- no application-specific loading UI
- no framework-specific state integration

## 解決方法

`docs/request-lifecycle.md` を低レベル runtime contract として更新し、state transition、repeated trigger determinism、`drop` / `replace` / `queue:first` / `queue:last` / `queue:all`、abort、network failure cleanup、lifecycle event 名と stable detail key を明文化した。

`RequestManager::complete` は current task id と一致する完了だけが queue を進めるようにし、replace 後に古い request の失敗 callback が到着しても新しい current request を消さないようにした。`replace` と `queue:last` で破棄される pending task は cancel 済みにしてから queue から外す。

`src/network/manager_test.mbt` に `drop`、`queue:all` FIFO、replace 後の stale completion cleanup の focused test を追加した。既存の `queue:first` / `queue:last` / `replace` test と合わせて、browser app scaffolding なしで pure な queue contract を確認する。

README の request lifecycle へのリンク文言を、queue / abort / lifecycle event details を含む contract への導線として明確にした。
