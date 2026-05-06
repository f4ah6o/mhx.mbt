# swap contract

`mhx` treats swapping as a low-level DOM primitive.

## Supported strategies

| Strategy | Behavior |
| --- | --- |
| `innerHTML` | replace target children |
| `outerHTML` | replace the target element itself |
| `beforebegin` | insert before the target |
| `afterbegin` | insert as the first child |
| `beforeend` | insert as the last child |
| `afterend` | insert after the target |
| `delete` | remove the target element |
| `none` | do not mutate the DOM |

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

## Lifecycle hooks around swap

- `mhx:beforeSwap` fires immediately before DOM mutation
- `mhx:afterSwap` fires after DOM mutation and recursive `mhx.process_tree(...)` processing
- `mx-swap="none"` still allows request hooks, but no `beforeSwap` / `afterSwap` DOM mutation work occurs

## Script and focus policy

- `mhx` does not sanitize HTML
- `mhx` does not add any special script execution layer beyond the browser's native DOM behavior for `innerHTML` / `insertAdjacentHTML`
- focus preservation is not currently guaranteed across swaps; callers should treat focus continuity as application responsibility
