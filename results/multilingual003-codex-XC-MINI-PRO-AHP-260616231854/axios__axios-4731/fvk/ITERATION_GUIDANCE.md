# FVK Iteration Guidance

Status: source V2 applied after auditing V1.

## Code Decision

V1 did not stand unchanged. It correctly mapped axios unlimited values to `Infinity`, but it did so for every transport branch. FVK finding F-002 and proof obligations PO-003/PO-004 showed that this changed native/custom option shape without being required by the public follow-redirects issue.

V2 keeps the bug fix and narrows the new assignment:

```js
if (config.maxBodyLength > -1) {
  options.maxBodyLength = config.maxBodyLength;
} else if (!config.transport && config.maxRedirects !== 0) {
  options.maxBodyLength = Infinity;
}
```

## Recommended Tests To Add Or Keep

No tests were edited or run. Suggested tests for a normal development environment:

- default `maxBodyLength` with redirect-capable HTTP transport and a large body should not fail due to the `follow-redirects` default.
- explicit `{ maxBodyLength: -1 }` with redirect-capable HTTP transport and a large body should not fail due to the `follow-redirects` default.
- explicit finite `{ maxBodyLength: 2000 }` should still reject larger buffered request data with `Request body larger than maxBodyLength limit`.
- `{ maxRedirects: 0 }` with default `maxBodyLength` should remain unlimited.
- custom `transport` with default `maxBodyLength` should not receive a new `Infinity` option unless the user explicitly configured a greater-than-`-1` value.

## Residual Work

- Documentation: F-004 remains open for a docs-scoped task. README should document that `maxBodyLength: -1` is the default unlimited sentinel in Node.
- Machine checking: run the commands in `fvk/PROOF.md` in an environment with K installed before treating any proof-subsumed tests as removable.
- Domain clarification: F-005 should be revisited only if axios wants to define behavior for malformed numeric values such as `NaN`.
