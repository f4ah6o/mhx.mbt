# Swap contract

`mhx` treats swapping as a low-level DOM primitive.
The contract is defined in terms of browser DOM operations, not framework
component lifecycles or virtual DOM reconciliation.

## Supported strategies

| Strategy | DOM primitive | Response body use |
| --- | --- | --- |
| `innerHTML` | `target.innerHTML = responseText` | used as HTML |
| `outerHTML` | `target.outerHTML = responseText` | used as HTML |
| `beforebegin` | `target.insertAdjacentHTML("beforebegin", responseText)` | used as HTML |
| `afterbegin` | `target.insertAdjacentHTML("afterbegin", responseText)` | used as HTML |
| `beforeend` | `target.insertAdjacentHTML("beforeend", responseText)` | used as HTML |
| `afterend` | `target.insertAdjacentHTML("afterend", responseText)` | used as HTML |
| `delete` | `target.remove()` | ignored |
| `none` | no DOM mutation | ignored |

`innerHTML` is the default strategy when neither configuration nor `mx-swap`
selects another strategy. `delete` and `none` still require a resolved target in
the current runtime because target resolution happens before strategy execution.

## Target resolution

Resolution order:

1. trigger-local `target:` modifier
2. `mx-target`
3. the triggering element itself

Supported target selector keywords:

- `this`
- `body`
- `document`
- `closest <selector>`
- `find <selector>`
- `next <selector>`
- `previous <selector>`
- CSS selector

`window` is not a valid swap target.

## Missing target behavior

If target resolution produces no DOM element at swap time:

- `mhx` emits `mhx:error`
- the error code is `MHX_SELECTOR_TARGET_NOT_FOUND`
- the response body is ignored
- queued follow-up requests still continue normally
- no swap lifecycle event is emitted because there is no target to swap

## Lifecycle hooks around swap

For a successful response with a resolved target and a mutating strategy:

1. `mhx:afterRequest` fires after the response succeeds.
2. `mhx:beforeSwap` fires immediately before the DOM primitive runs.
3. the selected DOM primitive runs.
4. `mhx.process_tree(...)` processes the affected target subtree.
5. `mhx:afterSwap` fires after processing.

`mhx:beforeSwap` and `mhx:afterSwap` are dispatched on the triggering element.
Their `detail` object contains stable descriptive fields:

- `phase`: `swapping` for `mhx:beforeSwap`, `completed` for `mhx:afterSwap`
- `trigger`: the trigger expression that caused the request
- `strategy`: the parsed swap option string
- `sourceElement`: a human-readable description of the triggering element
- `target`: a human-readable description of the resolved target

For `mx-swap="none"`, the current runtime resolves the target and emits
`mhx:beforeSwap` / `mhx:afterSwap`, but the selected primitive is a no-op and
the response body is not inserted. Request lifecycle hooks still fire.

For missing target errors, `mhx:error` is dispatched on the triggering element
with the structured selector error payload documented in
[`request-lifecycle.md`](./request-lifecycle.md). `mhx:beforeSwap` and
`mhx:afterSwap` are not emitted in that path.

## Script and focus policy

- `mhx` does not sanitize HTML
- `mhx` does not add any special script execution layer beyond the browser's native DOM behavior for `innerHTML`, `outerHTML`, and `insertAdjacentHTML`
- focus preservation is not currently guaranteed across swaps; callers should treat focus continuity as application responsibility
