# Document security boundary for HTML swapping

Created: 2026-05-05
Completed: 2026-05-11
Model: N/A

## Summary

Document the security boundary for mhx HTML fetching and swapping.

## Motivation

mhx fetches HTML fragments and inserts them into the DOM. The library should explicitly define its security responsibility boundary so consumers understand what is and is not protected by default.

## Proposed policy

Document whether mhx:

- sanitizes server responses by default
- executes or ignores `<script>` tags in swapped content
- assumes same-origin trusted fragments
- supports cross-origin requests
- validates or safely rejects invalid `mx-vals`
- exposes hooks for application-level sanitization

## Acceptance criteria

- `docs/security.md` exists
- README links to the security boundary
- script handling policy is explicit
- invalid / unsafe `mx-vals` behavior is tested
- cross-origin behavior is documented
- server trust assumptions are clear

## Non-goals

- no full HTML sanitizer implementation required by this issue
- no CSP framework required

## 解決方法

- `docs/security.md` を runtime responsibilities、application responsibilities、trust model、script handling、cross-origin guidance、related contracts に分けて整理した。
- HTML sanitizer、CSP、cross-origin trust policy は `mhx` の責務ではなく application 側の責務であることを明記した。
- script handling は `innerHTML` / `outerHTML` / `insertAdjacentHTML` の browser native behavior に従い、`mhx` は script blocker や sanitizer として扱えないことを明文化した。
- `mx-vals` の unsafe shape として array value と top-level array が `MHX_CONFIG_ERROR` になるテストを追加した。
