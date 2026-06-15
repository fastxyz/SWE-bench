# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims

The proof is over the abstract K core in `fvk/mini-astropy-table.k` and
`fvk/structured-column-spec.k`.

- C1: `convert(plainStructuredNdarray)` reaches
  `columnResult(plainStructuredNdarray)`.
- C2: `convert(explicitNdarrayMixin)` reaches
  `mixinResult(explicitNdarrayMixin)`.
- C3: `tableModuleNdarrayMixin` reaches `NdarrayMixinClass`.

## Symbolic Proof Sketch

For C1, the V2 source has no branch between mixin-handler handling and name
resolution that can rewrite a plain structured ndarray to `NdarrayMixin`. Under
PO-001, `isinstance(data, Column)` is false, `data_is_mixin` is false, and
`data0_is_mixin` is false. The branch chain skips `Column`, `data_is_mixin`,
`data0_is_mixin`, masked-array, and `None` cases, then reaches the normal
`else: col_cls = self.ColumnClass` branch. The final constructor call creates
the table's normal column class from the original structured data. This matches
the rewrite rule:

```k
convert(plainStructuredNdarray) => columnResult(plainStructuredNdarray)
```

For C2, `_is_mixin_for_table(data)` remains evaluated before all conversion
branches. An explicit `NdarrayMixin` is a valid mixin and not a `BaseColumn`, so
`data_is_mixin` is true. The unchanged branch copies or reuses the mixin, sets
its name, and returns it. This matches:

```k
convert(explicitNdarrayMixin) => mixinResult(explicitNdarrayMixin)
```

For C3, `astropy.table.__init__` imports `NdarrayMixin` from `.table`. V2 keeps
`table.py` binding that name with `from .ndarray_mixin import NdarrayMixin
# noqa: F401`, so the module lookup remains defined. This matches:

```k
tableModuleNdarrayMixin => NdarrayMixinClass
```

There are no loops in the changed control-flow slice, so no circularity or
termination measure is required. Partial correctness is sufficient for these
straight-line branch claims.

## Proof-Derived Findings

- F-001 was found by the compatibility proof obligation: V1 removed a public
  module binding needed by `astropy.table.__init__`. V2 fixes it.
- F-002 is an adequacy finding: the existing public test asserts the legacy
  behavior that public issue intent rejects.
- No remaining proof obligation requires a production source edit after V2.

## Machine-Check Commands

These commands are intentionally not executed in this environment:

```sh
kompile fvk/mini-astropy-table.k --backend haskell
kast --backend haskell fvk/structured-column-spec.k
kprove fvk/structured-column-spec.k
```

Expected result after a successful machine check: `kprove` returns `#Top` for
all three claims.

## Test Guidance

Do not remove tests based on this constructed proof alone. After machine
checking and running the normal project test suite in a suitable environment:

- Update the legacy structured-array assertions in `test_ndarray_mixin` so
  plain structured arrays are expected to be normal table columns.
- Keep explicit `NdarrayMixin` tests.
- Add or keep compatibility coverage for `from astropy.table import
  NdarrayMixin`.
