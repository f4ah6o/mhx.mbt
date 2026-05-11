# mhx npm package contract

`mhx` publishes a browser runtime bundle for `mx-*` hypermedia attributes.

## Install

```bash
npm install mhx
```

## ESM contract

The package supports both default and named ESM imports:

```js
import mhx, { init_mhx, process, handle_event, version } from "mhx";

init_mhx();
console.log(version);
process(document.body);
```

Stable ESM exports are:

- `default`
- `init_mhx`
- `process`
- `handle_event`
- `version`

Internal callback hooks are intentionally **not** exported.

## UMD / script tag contract

```html
<script src="https://unpkg.com/mhx/dist/mhx.umd.js"></script>
<script>
  mhx.init_mhx();
  mhx.process(document.body);
</script>
```

### CDN / integrity guidance

Use exact package versions for CDN URLs:

```text
https://unpkg.com/mhx@2026.1.22/dist/mhx.esm.js
https://unpkg.com/mhx@2026.1.22/dist/mhx.umd.js
https://cdn.jsdelivr.net/npm/mhx@2026.1.22/dist/mhx.esm.js
https://cdn.jsdelivr.net/npm/mhx@2026.1.22/dist/mhx.umd.js
```

If you need Subresource Integrity, compute the hash from the exact file you
serve and pin the same version in the URL:

```bash
curl -sL https://unpkg.com/mhx@2026.1.22/dist/mhx.umd.js | openssl dgst -sha384 -binary | openssl base64 -A
```

Use the result as `sha384-<hash>`:

```html
<script
  src="https://unpkg.com/mhx@2026.1.22/dist/mhx.umd.js"
  integrity="sha384-<hash>"
  crossorigin="anonymous"
></script>
```

## Published files

The published package is limited to:

- `dist/mhx.esm.js`
- `dist/mhx.umd.js`
- `README.md`
- `README.mbt.md`
- `README.npm.md`
- `LICENSE`
- npm-generated `package.json`

`pnpm build` verifies this contract via `npm pack --dry-run --json`.

## TypeScript / side effects

- TypeScript declaration files are **not** published yet
- the package is marked with `sideEffects: true` because import-time FFI bootstrap wiring is intentional

## Browser compatibility

Current target assumptions:

- modern browsers with ES modules or classic script execution
- `fetch`, `AbortController`, `CustomEvent`, `MutationObserver`, `FormData`, and `URLSearchParams`

If you need older browsers, provide your own polyfills before loading `mhx`.

## Security notes

- `mhx` does not sanitize fetched HTML
- `mhx` treats fetched fragments as trusted application output
- `mx-vals` accepts only flat JSON scalar values

See [docs/security.md](https://github.com/f4ah6o/mhx.mbt/blob/main/docs/security.md).

## Versioning

This repository intentionally uses separate version domains:

- MoonBit package version: `moon.mod.json` / `@mhx.version`
- npm runtime version: `package.json.version` / JS `version` export

See [docs/versioning.md](https://github.com/f4ah6o/mhx.mbt/blob/main/docs/versioning.md).

## Minimal vanilla HTML example

```html
<!doctype html>
<html lang="en">
  <body>
    <button mx-get="/fragments/hello" mx-target="#result">Load</button>
    <div id="result"></div>

    <script type="module">
      import { init_mhx } from "https://unpkg.com/mhx/dist/mhx.esm.js";
      init_mhx();
    </script>
  </body>
</html>
```
