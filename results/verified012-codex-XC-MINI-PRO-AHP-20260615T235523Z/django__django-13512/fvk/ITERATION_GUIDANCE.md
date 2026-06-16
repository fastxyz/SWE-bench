# FVK Iteration Guidance

Status: V1 stands unchanged after FVK audit. Constructed, not machine-checked.

## Code Decision

No additional source edit is recommended.

Rationale:

- `F-001` is resolved by `PO-002`: the display call now uses `ensure_ascii=False`.
- `F-002` is discharged by `PO-001`: invalid JSON redisplay remains unchanged.
- `F-003` is discharged by `PO-005`: database serialization remains untouched.
- `F-004` is discharged by `PO-004`: custom encoders remain wired through `cls=self.encoder`.
- `F-005` is a proof execution boundary caused by the no-execution constraint, not a code defect.

## Future Tests to Add or Keep

Do not edit tests in this benchmark workspace. In a normal development pass, add tests for:

- `forms.JSONField().prepare_value({"country": "中国"})` displaying readable Unicode instead of `\u4e2d\u56fd`.
- A bound form redisplay path where submitted valid JSON contains non-ASCII text and another form field is invalid.
- A custom encoder path to confirm `cls=self.encoder` remains honored with `ensure_ascii=False`.
- Invalid JSON redisplay to confirm `InvalidJSONInput` remains un-dumped.

Keep database serialization tests because `PO-005` is a frame condition over untouched code, not a proof that database backends accept every Unicode storage case.

## Machine-Check Guidance

The constructed K proof can be checked later with:

```sh
cd fvk
kompile mini-json-form.k --backend haskell
kast --backend haskell jsonfield-prepare-value-spec.k
kprove jsonfield-prepare-value-spec.k
```

Only after `kprove` returns `#Top` should any test redundancy recommendation be considered. This FVK pass recommends adding coverage, not deleting tests.

## If A Future Audit Fails

If future machine checking rejects the mini semantics syntax, repair the K artifact rather than changing Django source. The source-level proof obligations are branch-local and already trace to public intent. A source change would be justified only if a future finding shows one of these obligations is false in the real code path.
