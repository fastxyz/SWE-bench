# FVK Notes

## Decision summary

V1 did not stand unchanged. The FVK audit confirmed the original behavioral fix for `follow-redirects`, but it also found that V1 assigned `options.maxBodyLength = Infinity` on native and custom transport paths where the public issue did not require a new option property. I revised the source to keep the `Infinity` mapping only for the built-in redirect-capable transport path.

## Source change

Changed `repo/lib/adapters/http.js`.

- F-001 and PO-001/PO-002 justify adding an unlimited downstream value for the `follow-redirects` path. Axios' default `maxBodyLength: -1` is unlimited, but `follow-redirects` does not share that sentinel; it needs `Infinity`.
- F-002 and PO-003/PO-004 justify narrowing V1. When `maxRedirects === 0`, Node's native transport does not need the `Infinity` override. When `config.transport` is supplied, the public issue does not justify changing the custom transport's default option shape.
- F-003 and PO-005 justify keeping the existing greater-than-`-1` branch intact. Explicit finite limits and explicit `Infinity` still pass through unchanged.

The resulting source logic is:

```js
if (config.maxBodyLength > -1) {
  options.maxBodyLength = config.maxBodyLength;
} else if (!config.transport && config.maxRedirects !== 0) {
  options.maxBodyLength = Infinity;
}
```

## Decisions not to change other files

- Tests were not changed, per task instructions.
- README/changelog were not changed. F-004 and PO-006 record that the public issue includes a documentation obligation, but this benchmark phase asks for a source-code repair and forbids using test/evaluator feedback. The documentation gap is preserved as follow-up guidance in `fvk/ITERATION_GUIDANCE.md`.
- No generated `dist/` files were changed. The audited behavior is in the Node adapter under `lib/`, and the package entry point loads `lib/axios`.

## Verification status

The FVK proof is constructed, not machine-checked. The exact commands to run later are in `fvk/PROOF.md`, but this session intentionally did not run tests, Node code, Python, `kompile`, `kast`, or `kprove`.
