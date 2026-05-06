# Document security boundary for HTML swapping

Created: 2026-05-05
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
