# PROOF

Status: constructed, not machine-checked.

## Claims Proved in the Mini Model

The proof targets the constructor-preservation property of
`Query.resolve_lookup_value()` for the two iterable categories handled by the
source branch: list and tuple.

The machine-oriented artifacts are:

- `fvk/mini-python-resolve-lookup.k`
- `fvk/resolve-lookup-value-spec.k`

Expected commands, not executed in this environment:

```sh
kompile fvk/mini-python-resolve-lookup.k --backend haskell
kast --backend haskell fvk/resolve-lookup-value-spec.k
kprove fvk/resolve-lookup-value-spec.k
```

Expected result after a successful machine check: `#Top`.

## Proof Sketch

### List input

Start with an abstract state whose `<k>` cell contains:

```k
resolveLookupValue(pyList(VS), CR, AJ, SC)
```

The mini semantics has a value-level rule corresponding to the Python
`elif isinstance(value, (list, tuple))` branch and the V1 reconstruction for
non-tuple inputs:

```k
resolveLookupValue(pyList(VS), CR, AJ, SC)
  => pyList(resolveLookupValues(VS, CR, AJ, SC))
```

This is one semantic step. By Axiom plus framing, the result keeps the list
constructor. The recursive helper `resolveLookupValues()` resolves each element
with the same flags and preserves sequence order. The empty sequence closes by
the base rule; the non-empty sequence closes by one head step plus circular use
of the helper claim on the tail.

Discharged obligations: PO-1 and PO-3.

### Tuple input

Start with:

```k
resolveLookupValue(pyTuple(VS), CR, AJ, SC)
```

The mini semantics rule corresponding to the tuple side of V1 is:

```k
resolveLookupValue(pyTuple(VS), CR, AJ, SC)
  => pyTuple(resolveLookupValues(VS, CR, AJ, SC))
```

By Axiom plus framing, the result keeps the tuple constructor. The same helper
claim discharges element order, length, and per-element resolution.

Discharged obligations: PO-2 and PO-3.

### Top-level expression and atom inputs

For `fexpr(X)`, the mini semantics rewrites to
`fresolved(X, CR, AJ, SC)`, matching the Python branch that adds
`simple_col` only for `F` expressions.

For `expr(X)`, the mini semantics rewrites to `resolved(X, CR, AJ)`,
matching the ordinary expression path.

For `atom(X)`, the mini semantics rewrites to `atom(X)`, matching the Python
fallthrough.

Discharged obligation: PO-4.

### Exact lookup integration

The proof of the helper itself is not enough to show the issue is fixed; the
preserved list must reach exact lookup preparation. Source inspection supplies
the integration proof:

1. `build_filter()` binds `value = self.resolve_lookup_value(...)`.
2. The same `value` is passed to `self.build_lookup(...)`.
3. `build_lookup()` constructs the lookup class with that RHS.
4. `Exact` uses `FieldGetDbPrepValueMixin`, whose non-iterable exact path passes
   the whole RHS value to the field's `get_db_prep_value()`.

Therefore the top-level list preserved by V1 is the value seen by type-sensitive
field preparation.

Discharged obligation: PO-5.

## Adequacy Check

The formal claims distinguish `pyList(VS)` from `pyTuple(VS)`, so the model can
observe the exact defect axis named by the public issue. A model that collapsed
both to an opaque iterable would be inadequate; this one does not.

The model abstracts full Django expression resolution. That abstraction is
adequate for this bug because expression resolution's internal result is not
the reported failure. The reported failure is the top-level reconstruction
constructor after element resolution.

Exact subclass preservation is intentionally not claimed. That point is
under-specified by the allowed public evidence and is tracked as F-003/PO-7.

## Test Redundancy Recommendation

No tests were run and no test files were changed.

If the K claims were machine-checked, focused unit tests that assert only the
in-domain list/tuple constructor-preservation behavior of
`resolve_lookup_value()` would be candidates for redundancy. Integration tests
for actual ORM exact lookups, type-sensitive custom fields, database behavior,
and subclass behavior should be kept because the mini proof abstracts those
layers or marks them outside the proven contract.

## Residual Risk

- The proof is constructed, not machine-checked.
- The proof is partial correctness over a mini semantics, not full Python or
  full Django semantics.
- Exact concrete subclass preservation remains an unresolved intent question.

