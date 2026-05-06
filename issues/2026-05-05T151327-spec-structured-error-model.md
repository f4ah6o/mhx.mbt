# Stabilize MhxError as a structured error model

Created: 2026-05-05
Model: N/A

## Summary

Stabilize `MhxError` as a structured, machine-readable low-level error model.

## Motivation

Applications and higher-level libraries should not need to parse error message strings. mhx should expose stable error categories and codes.

## Proposed categories

- `ParseError`
- `SelectorError`
- `NetworkError`
- `TimeoutError`
- `SwapError`
- `FfiError`
- `InternalError`

## Proposed fields

Each error should include:

- `code`
- `message`
- `attribute`, when applicable
- `sourceElement`, when available
- `position`, for parse errors
- `recoverable`, when meaningful

## Acceptance criteria

- public error shape is documented
- errors are serializable for logging
- error handler receives structured data
- tests assert stable error codes, not only message text
- parse errors include enough location information for diagnostics

## Non-goals

- no application-specific error UI
- no localization requirement
