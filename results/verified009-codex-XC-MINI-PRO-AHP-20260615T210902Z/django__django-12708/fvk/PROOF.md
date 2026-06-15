# PROOF

Status: constructed, not machine-checked. No K command was run.

## Claims

The proof uses `mini-schema.k` and `schema-editor-spec.k`.

- SPEC-C0 localizes the pre-fix failure: with `_uniq` and `_idx` both
  satisfying `index=True`, the old lookup selects both and reaches
  `wrongCount`.
- SPEC-C1 proves V1 selects and deletes `_idx` when `_uniq` appears first.
- SPEC-C2 proves V1 selects and deletes `_idx` when `_idx` appears first.

## Constructed symbolic proof

### SPEC-C0

Start state:

```text
deleteIndexTogetherV0("a,b",
  constraint("_uniq", "a,b", index=true, unique=true, excluded=false);
  constraint("_idx", "a,b", index=true, unique=false, excluded=false))
```

Symbolic execution rewrites `deleteIndexTogetherV0` to
`deleteOne(filterIndexOnly(...))`. The `filterIndexOnly` rule includes any
same-column, non-excluded object with `index=true`, regardless of `unique`.
Therefore it returns:

```text
"_uniq", "_idx", .Names
```

`deleteOne()` on two names rewrites to `wrongCount(...)`. This matches the issue
symptom "Found wrong number (2)" and localizes the cause to an under-specific
filter.

### SPEC-C1

Start state is the same object set, ordered `_uniq` then `_idx`, but using
`deleteIndexTogetherV1`. Symbolic execution rewrites to
`deleteOne(filterIndexTogetherDelete(...))`.

The first object has `unique=true`, so the V1 filter excludes `_uniq`. The second
object has `index=true`, `unique=false`, and `excluded=false`, so the V1 filter
includes `_idx`. The filtered list is:

```text
"_idx", .Names
```

`deleteOne()` rewrites that singleton list to `deleted("_idx")`.

### SPEC-C2

SPEC-C2 repeats the V1 proof with `_idx` before `_uniq`. The V1 filter includes
`_idx`, excludes `_uniq`, and again produces the singleton list
`"_idx", .Names`, so `deleteOne()` reaches `deleted("_idx")`. This discharges
the order adequacy check: the proof does not depend on the unique constraint
appearing first.

## Source-level conclusion

V1's source edit is exactly the semantic difference between SPEC-C0 and
SPEC-C1/SPEC-C2:

```python
{'index': True, 'unique': False}
```

Because `_constraint_names()` already applies optional flag filters by equality,
adding `unique=False` excludes same-column unique objects and leaves the
non-unique `index_together` index selectable.

## Residual risk

- The proof is over a mini schema-editor model, not full Python/Django
  semantics. It preserves the property-relevant axes: columns, `index`,
  `unique`, and exclusion.
- The proof is constructed, not machine-checked.
- Termination is trivial in the finite list model but not separately
  machine-verified.
- PO5 remains open for a future migration-autodetector/state design.

## Machine-check commands

These commands are for a later environment and were not executed here.

```sh
cd fvk
kompile mini-schema.k --backend haskell
kast --backend haskell schema-editor-spec.k
kprove schema-editor-spec.k
```

Expected result after a successful machine check: `#Top` for the claims in
`schema-editor-spec.k`.
