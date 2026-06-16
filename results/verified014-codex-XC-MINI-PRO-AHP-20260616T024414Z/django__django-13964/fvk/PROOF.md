# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
tests, Python, or K tooling were run.

## Claims

The proof core is in `mini-django-save.k` and `django-save-spec.k`.

- C1 proves the reported stale-empty-string path: a cached relation with
  `att == EmptyVal`, related `PK != NoneVal`, and target `PK` terminates with
  `att == PK` and cache still valid.
- C2 proves the unsaved-object guard: a cached relation with `PK == NoneVal`
  reaches the `ValueError` outcome before refresh.
- C3 proves non-empty mismatch behavior: a non-empty local attname is preserved,
  and a target/local mismatch clears the cache.

## Proof Sketch

### C1: Empty local FK refresh

Initial state:

`<k> prepare(true, PK, PK) </k>`, `<att> EmptyVal </att>`,
`<cache> Cached </cache>`, `PK =/=K NoneVal`.

Symbolic execution:

1. The uncached, falsey-object, and `NoneVal` rules do not match.
2. `isEmptyValue(EmptyVal) => true`, so the refresh rule applies and rewrites
   `<att> EmptyVal => PK </att>`, with the continuation
   `compareTarget(PK)`.
3. `compareTarget(PK)` sees `<att> PK </att>`, so the cache-preserving rule
   applies and terminates with `.K`.

Post-state:

`<att> PK </att>`, `<cache> Cached </cache>`, `<outcome> Normal </outcome>`.

This discharges O1 and the issue's `"foo"` post-state by instantiating
`PK := FooVal`.

### C2: Unsaved related object guard

Initial state:

`<k> prepare(true, NoneVal, TARGET) </k>`, `<cache> Cached </cache>`.

Symbolic execution:

The `NoneVal` guard rule matches before the refresh rules and rewrites
`<outcome> Normal => ValueError </outcome>`, then terminates.

Post-state:

The modeled outcome is `ValueError`; the local attname is not refreshed.

This discharges O2.

### C3: Non-empty stale value cache clearing

Initial state:

`<k> prepare(true, PK, TARGET) </k>`, `<att> ATT </att>`,
`PK =/=K NoneVal`, `notBool isEmptyValue(ATT)`, `TARGET =/=K ATT`.

Symbolic execution:

1. The refresh rule is blocked by `notBool isEmptyValue(ATT)`.
2. The non-empty rule leaves `<att> ATT </att>` unchanged and continues to
   `compareTarget(TARGET)`.
3. The mismatch rule applies because `TARGET =/=K ATT` and rewrites
   `<cache> Cached => NotCached </cache>`.

Post-state:

`<att> ATT </att>`, `<cache> NotCached </cache>`,
`<outcome> Normal </outcome>`.

This discharges O3.

## Loop/Frame Proof

The source loop iterates over `self._meta.concrete_fields`. The induction
argument is:

- Base: before processing any fields, all fields retain their pre-state.
- Step: one field iteration either skips because it is not a cached relation,
  skips because the cached object is falsey, raises on `obj.pk is None`, or
  applies C1/C3 to the current field. The code references the current `field`
  for `attname`, cache reads, cache deletes, and target comparison, so other
  fields are framed unchanged.
- Conclusion: after the finite loop, every processed field satisfies the
  corresponding per-field postcondition unless the method raised earlier.

This discharges O4. It is a source-structure proof obligation, not a
machine-checked K loop claim.

## Exact Commands To Machine-Check Later

These commands are recorded only; they were not executed.

```sh
cd fvk
kompile mini-django-save.k --backend haskell
kast --backend haskell django-save-spec.k
kprove django-save-spec.k
```

Expected successful result:

`#Top`

## Test Guidance

No test may be removed based on this constructed proof. Keep existing tests
until the K commands are run and return `#Top`. Add or keep a regression test
for the CharField primary-key issue trace described in FINDINGS F1.
