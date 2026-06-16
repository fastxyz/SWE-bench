# Iteration Guidance

Status: constructed, not machine-checked.

## Decision

V1's source-code change stands. The FVK audit did not find a code defect in the
message interpolation. It did find stale public documentation, so V2 updates
`repo/docs/ref/checks.txt`.

## Code guidance

No further source-code change is recommended. Keep the invalid-branch message in
`repo/django/contrib/admin/checks.py` in the form:

`The value of '<label>' refers to '<field_name>', which is not a callable, an attribute of '<ModelAdmin>', or an attribute of '<model>'.`

This is justified by F-01 and PO-01 through PO-04.

## Documentation guidance

Keep `docs/ref/checks.txt` aligned with the runtime message. This is justified
by F-02 and PO-05.

## Test guidance

Do not edit tests in this benchmark. Outside the benchmark, update the public
`admin.E035` expectations to include the invalid field value. This is justified
by F-03 and PO-06.

## Verification guidance

The K proof has not been run. A future environment with K available should run:

```sh
cd fvk
kompile mini-admin-checks.k --backend haskell
kast --backend haskell readonly-fields-spec.k
kprove readonly-fields-spec.k
```

Until that returns `#Top`, treat proof-based test removal as recommendation-only.
