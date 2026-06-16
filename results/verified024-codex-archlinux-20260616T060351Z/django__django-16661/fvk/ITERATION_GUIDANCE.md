# Iteration Guidance

Status: V1 stands unchanged.

## Decision

No V2 source edit is justified. The FVK audit found that V1 satisfies the
public-intent obligations and preserves the important compatibility behavior
that a narrower fix could have broken.

Trace:

- F1 / PO3 justify keeping the actual-path candidate in V1.
- F2 / PO4 justify keeping the trailing target-field stripping loop.
- F3 / PO2 and PO4 justify preserving the original collapsed direct-relation
  behavior.
- F4 / PO5 confirms V1 does not authorize a real field beyond the configured
  filter path.
- F5 / PO6 requires keeping all verification claims labeled as constructed, not
  machine-checked.

## Recommended Future Tests

Do not edit tests in this task. If tests are added later, cover:

- `lookup_allowed("restaurant__place__country", value)` with
  `list_filter = ["restaurant__place__country"]` returns `True`.
- `lookup_allowed("restaurant__place__country__id__exact", value)` with the
  same filter returns `True`.
- `lookup_allowed("restaurant__place__exact", value)` with
  `list_filter = ["restaurant"]` returns `True` for a related model whose
  primary key is relational.
- `lookup_allowed("restaurant__place__country__name", value)` with
  `list_filter = ["restaurant__place__country"]` returns `False` unless the
  extended field path is configured.

## Machine-Check Follow-Up

The commands recorded in `fvk/PROOF.md` were not run. In an environment with K,
run:

```sh
kompile fvk/mini-admin-lookup.k --backend haskell
kast --backend haskell fvk/lookup-allowed-spec.k
kprove fvk/lookup-allowed-spec.k
```

Keep all tests until the claims are machine-checked and a test-by-test
redundancy report is produced.
