# request lifecycle

`mhx` uses a deterministic request lifecycle so repeated triggers can be reasoned about without framework-specific state.
This document is the low-level runtime contract for request scheduling, queueing, aborts, network failures, and lifecycle events.

## Lifecycle states

Lifecycle state is element-local. A request-capable element starts in `idle`.

| State | Meaning | Entered from |
|-------|---------|--------------|
| `idle` | No request is active and no queued task is selected for execution. | initial state, `completed`, `failed`, `aborted` |
| `scheduled` | A trigger matched after `delay` / `throttle` / `debounce` coordination and is being offered to the request manager. | `idle`, `in_flight` |
| `in_flight` | The fetch bridge owns an active request callback. | `scheduled` |
| `swapping` | A successful response is being applied to the selected DOM target. | `in_flight` |
| `completed` | The request and any DOM swap finished. | `swapping`, `in_flight` when `mx-swap="none"` |
| `failed` | Fetch, response handling, target resolution, or swap preparation failed. | `in_flight` |
| `aborted` | Runtime coordination cancelled a current or queued task. | `scheduled`, `in_flight` |

The canonical successful path is:

```text
idle -> scheduled -> in_flight -> swapping -> completed -> idle
```

The canonical non-swap success path is:

```text
idle -> scheduled -> in_flight -> completed -> idle
```

The canonical failure path is:

```text
idle -> scheduled -> in_flight -> failed -> idle
```

The canonical replacement path for an active request is:

```text
in_flight(old) -> aborted(old) -> scheduled(new) -> in_flight(new)
```

## Repeated trigger determinism

Timing modifiers run before request manager scheduling.
After a trigger passes `delay`, `throttle`, `debounce`, `changed`, `once`, filter, and event propagation checks, the request manager observes one task at a time in source event order.

For one element:

- `drop` never changes the active request while busy.
- `replace` always cancels the current request and removes pending requests before starting the new request.
- `queue:first` preserves the earliest pending request and drops later pending requests while busy.
- `queue:last` replaces any pending request with the latest request while busy.
- `queue:all` preserves every pending request in FIFO order.
- completing a stale task id is ignored and cannot clear the current request.

These rules make repeated triggers deterministic even when browser fetch callbacks for aborted or failed requests arrive after a replacement request has started.

## Queue modes

`mx-sync` controls element-local concurrency.
The default is `drop`.

| Mode | Busy behavior | Pending shape |
|------|---------------|---------------|
| `drop` | Ignore the new trigger. | no pending task is added |
| `replace` | Cancel the current task and execute the new task immediately. | existing pending tasks are cancelled and removed |
| `queue:first` | Keep the new task only when no pending task exists. | at most one pending task |
| `queue:last` | Replace any pending task with the new task. | at most one pending task |
| `queue:all` | Append the new task. | FIFO list |

Trigger-local queue modifiers reuse the same vocabulary: `queue:drop`, `queue:replace`, `queue:first`, `queue:last`, and `queue:all`.
They should not be combined with `mx-sync="queue ..."` on the same element because both configure the same low-level queue contract.
That overlap is a validation error, not a precedence rule.

## Abort behavior

Abort is runtime coordination, not application failure.

- `replace` aborts the active request before the replacement task becomes current.
- `cancel_all` aborts the active request and every pending task for the element.
- `queue:last` cancels the pending task it replaces.
- A cancelled task is marked locally and, if it has an active fetch callback id, the JS fetch bridge aborts the corresponding `AbortController`.
- An abort callback from an old request is treated as stale once another task is current; it must not clear the new current task or run a stale swap.
- Aborted requests may still produce `mhx:afterRequest` / `mhx:error` from the browser callback path, but queue advancement is guarded by task id.

## Failure cleanup

Network failure, non-OK response handling, and target resolution failure all finish the current task and then advance the queue.
The queue cleanup rule is:

- if the completed or failed task id matches the current task, clear it;
- if pending tasks exist, promote the first pending task to current;
- if no pending tasks exist, return to `idle`;
- if the task id is stale, ignore it and leave the queue unchanged.

This prevents network failure from leaving stale queue state and prevents delayed failure callbacks from erasing newer replacement requests.

## Lifecycle events

`mhx` dispatches bubbling `CustomEvent`s from the source element.
The stable event names are:

| Event | Phase values | Meaning |
|-------|--------------|---------|
| `mhx:beforeRequest` | `in_flight` | fetch is about to start |
| `mhx:afterRequest` | `afterRequest` | fetch finished or failed |
| `mhx:beforeSwap` | `swapping` | response is about to be swapped into the DOM |
| `mhx:afterSwap` | `completed` | swap completed |
| `mhx:error` | `failed` or event-specific error payload | request, swap, config, selector, network, abort, or FFI error |

Request event `detail` has these stable keys:

- `phase`
- `url`
- `method`
- `trigger`
- `sourceElement`
- `status`
- `error`

Swap event `detail` has these stable keys:

- `phase`
- `trigger`
- `strategy`
- `sourceElement`
- `target`

`mhx:error` from structured runtime errors has these stable keys:

- `error`
- `sourceElement`

`status` is `null` when no HTTP status is available.
`error` is `null` for successful request events and the full structured
`MhxError` JSON object for request failure events. See
[error model](./error-model.md) for the stable error fields.
