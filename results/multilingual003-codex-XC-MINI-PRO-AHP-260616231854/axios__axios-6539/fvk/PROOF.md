# Constructed Proof

Status: constructed, not machine-checked.

## Claim Summary

The proof targets the local adapter decision:

```js
const fullPath = buildFullPath(config.baseURL, config.url);
if (isProtocolRelativeURL.test(fullPath)) {
  return reject(new AxiosError('Invalid URL', AxiosError.ERR_INVALID_URL, config));
}
const parsed = new URL(fullPath, 'http://localhost');
```

The formal model in `mini-js-url.k` abstracts URLs into a leading character sequence over four classes: C0/space, `/`, `\`, and other. This abstraction is property-complete for the defect because the proof only depends on whether the URL parser can see an authority-form prefix before the fallback base supplies a protocol.

## Proof Sketch

1. `prepare(U)` rewrites to `isProtocolRelativeURL(U) ~> decide(U)`.
2. If `U` begins with C0/space, `isProtocolRelativeURL(c0 U)` recursively strips the prefix. This models URL parser leading C0/space trimming.
3. If the first two non-trimmed characters are any pair of `/` or `\`, `isProtocolRelativeURL(U)` rewrites to `true`.
4. `true ~> decide(U)` rewrites to `rejectInvalid`. This discharges O-001 and O-003.
5. If the input starts with `other`, or starts with a single separator followed by `other`, `isProtocolRelativeURL(U)` rewrites to `false`.
6. `false ~> decide(U)` rewrites to `parseWithFallback`. This discharges O-002 and O-004 for representative non-authority relative classes.
7. Source inspection confirms the same predicate and rejection branch exist in both changed Node adapter files. This discharges O-005.
8. Source inspection confirms the rejection constructs `new AxiosError('Invalid URL', AxiosError.ERR_INVALID_URL, config)`. This discharges O-006.

## Proof-Derived Findings

- F-001 was discovered by comparing V1's `^\s*//` predicate against O-001's full authority-form class. V2 fixes it with `/^[\u0000-\u0020]*[\\/]{2}/`.
- F-002 was confirmed from package exports and fixed by keeping the CommonJS Node bundle in sync.
- F-003 confirms no browser-adapter change is justified by the server-side intent.

## Machine Check Commands

These commands are intentionally not executed in this benchmark:

```sh
kompile fvk/mini-js-url.k --backend haskell
kast --backend haskell fvk/axios-url-spec.k
kprove fvk/axios-url-spec.k
```

Expected result if machine-checked later: `#Top`.

## Test Guidance

Do not remove tests based on this constructed proof alone. If tests can be edited in a normal development setting, add or keep coverage for:

- `//host` rejected in the Node HTTP adapter.
- `/\host`, `\/host`, and `\\host` rejected in the Node HTTP adapter.
- leading C0/space before `//host` rejected.
- ordinary `/path` with `baseURL` still proceeds to the configured host.

