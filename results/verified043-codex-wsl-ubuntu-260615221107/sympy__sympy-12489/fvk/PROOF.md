# Constructed Proof

Status: constructed, not machine-checked.

No tests, Python code, `kompile`, `kast`, or `kprove` commands were executed.

## Machine-Check Commands Not Run

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/permutation-subclass-spec.k
kprove fvk/permutation-subclass-spec.k
```

Expected machine-check result if the mini semantics and claims parse and
discharge: `#Top`.

## Trusted Base

- Adequacy of the class-tag mini semantics for the audited property.
- K reachability proof system and Haskell backend, once actually run.
- The abstraction that valid array normalization has already happened before
  the class-allocation step being audited.

## Proof Sketch

### PO1 / K1: `_af_new`

Initial state:

```k
<k> afNew(C, A) </k>
<result> noObj </result>
```

The `afNew` semantic rule rewrites the computation to `.K` and the result cell
to `obj(C, A)`. By Axiom plus framing, the claim reaches the post-state in one
step. This corresponds to V1's `Basic.__new__(cls, perm)` followed by preserving
`perm` as `_array_form`.

### PO2 / K2: `__new__` Fast Paths

Initial state:

```k
<k> constructorFast(C, CASE, A) </k>
<result> noObj </result>
```

The `constructorFast` rule rewrites to `afNew(C, A)`. By transitivity and K1,
the final result is `obj(C, A)`. This covers V1 branches that now call
`cls._af_new(...)`.

### PO3 / K3-K5: Fallthrough and Existing Permutations

The array/cyclic-form fallthrough path has a direct allocation rule
`constructorArray(C, A) => obj(C, A)`, matching source
`Basic.__new__(cls, aform)`.

For existing objects, the helper `existingResult(C, O)` has two cases:

- if `O` is already an instance of `C`, return `O`;
- otherwise return `obj(C, A)`.

The case `constructExisting(Sub, obj(Perm, A))` therefore reaches
`obj(Sub, A)`, while `constructExisting(Perm, obj(Sub, A))` reaches the existing
`obj(Sub, A)`. This matches V1's `isinstance(a, cls)` guard and subclass
conversion.

### PO4 / K6-K7: Fresh Results from Methods

For instance operations, `operationFresh(obj(C, oldA), A)` rewrites to
`afNew(C, A)`. K1 then gives `obj(C, A)`.

For classmethods, `classmethodFresh(C, A)` rewrites to `afNew(C, A)`. K1 then
gives `obj(C, A)`.

This corresponds to V1 replacing base-helper calls with `self._af_new`,
`cls._af_new`, and current-class dispatch where a dynamic class is available.

### PO5 / K8: External Base Alias

`moduleAliasAfNew(A)` rewrites to `afNew(Perm, A)`. K1 then gives
`obj(Perm, A)`. This models external source aliases such as
`_af_new = Permutation._af_new`, which are intentionally bound to the base
class.

## Completeness Check

The proof covers the full intent slice that caused the issue:

- `_af_new` allocation class;
- `__new__` branches that delegate to `_af_new`;
- construction from existing permutation objects;
- inherited methods and classmethods with dynamic class information;
- compatibility of base-bound external aliases.

The proof does not cover full permutation validation, all array algebra, or
termination/performance of ranking algorithms. `FINDINGS.md` records that as a
proof capability boundary, not a V1 code bug.

## Test Recommendations

No test files were edited. After machine-checking and normal project test
execution in an environment that permits it, direct unit tests for the following
would be subsumed by the formal class-tag claims:

- subclass `_af_new` returns subclass;
- subclass constructor fast paths return subclass;
- subclass construction from a base `Permutation` returns subclass;
- inherited fresh-result operations preserve subclass.

Keep existing algebra, validation, integration, and performance tests because
this proof does not cover those behaviors.

