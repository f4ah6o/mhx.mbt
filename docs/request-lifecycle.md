# request lifecycle

`mhx` uses a deterministic request lifecycle so repeated triggers can be reasoned about without framework-specific state.

## Lifecycle states

1. `idle` — no request is active for the element
2. `scheduled` — an event matched and the request is about to be coordinated
3. `in_flight` — the fetch bridge is active
4. `swapping` — a successful response is being applied to the DOM
5. `completed` — request finished and any swap hook finished
6. `failed` — request or swap preparation failed
7. `aborted` — the in-flight request was cancelled by runtime coordination

## Sync / queue semantics

`mx-sync` controls element-local concurrency:

- `drop` — ignore a new trigger while one request is in flight
- `replace` — cancel the current request and immediately execute the new one
- `queue:first` — keep only the first queued request while busy
- `queue:last` — keep only the most recent queued request while busy
- `queue:all` — preserve all queued requests in order

Trigger-local queue modifiers reuse the same queue vocabulary, but should not overlap with `mx-sync="queue ..."`.

## Failure and abort behavior

- failed network responses emit `mhx:error` and clear the active queue slot
- cancelling a queued or active request removes its callback and prevents stale swaps from winning races
- a missing swap target fails after the network completes; no DOM swap is performed

## Lifecycle hooks

`mhx` dispatches bubbling `CustomEvent`s from the source element:

- `mhx:beforeRequest`
- `mhx:afterRequest`
- `mhx:beforeSwap`
- `mhx:afterSwap`
- `mhx:error`

`event.detail` is a JSON-shaped object containing stable keys such as:

- `phase`
- `url`
- `method`
- `trigger`
- `sourceElement`
- `status` (when available)
- `error` (for `mhx:error` and failed request hooks)

## Queue guarantees

- `queue:first` preserves the earliest queued request and drops later queued requests while busy
- `queue:last` replaces intermediate queued requests
- `queue:all` keeps FIFO ordering
- queue state is cleared when a request completes or fails
