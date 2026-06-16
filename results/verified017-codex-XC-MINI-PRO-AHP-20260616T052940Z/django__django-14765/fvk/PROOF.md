# PROOF

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## What Is Proved

For `ProjectState.__init__(models=None, real_apps=None)`, assuming normal
Python assertion semantics:

- `real_apps is None` reaches successful construction with an empty
  `self.real_apps`.
- `real_apps` as an empty or non-empty set reaches successful construction with
  `self.real_apps` set to that provided set.
- `real_apps` as a non-`None` non-set reaches `AssertionError` and is not
  converted.
- Successful construction preserves the unrelated field behavior for
  `models`, `is_delayed`, and `relations`.

## Claims

The K claims are in `fvk/projectstate-spec.k`:

- `PROJECTSTATE-NONE` discharges `PO1` and `PO4`.
- `PROJECTSTATE-EMPTY-SET` discharges the empty-set half of `PO2` and `PO4`.
- `PROJECTSTATE-NONEMPTY-SET` discharges the non-empty-set half of `PO2` and
  `PO4`.
- `PROJECTSTATE-NONSET-ASSERTS` discharges `PO3`.

There are no loop circularities: the audited constructor branch is acyclic.

## Constructed Proof Sketch

1. Start from a symbolic constructor call represented by
   `initProjectState(<real_apps shape>)`.
2. The mini semantics first assigns the unchanged `models` field.
3. Case split on the `real_apps` shape:
   - `none`: rewrite to successful construction and place an empty set in the
     `realAppsAttr` cell.
   - `emptySet` or `nonEmptySet`: the assertion side condition is true, so
     rewrite to successful construction and place the same set shape in the
     `realAppsAttr` cell.
   - `nonSet`: the assertion side condition is false, so rewrite to
     `assertionError` and do not run the later successful-construction field
     assignments.
4. For successful paths, the `finishOk` rule assigns `isDelayed = false`,
   `relations = none`, and result `ok`.
5. Each right-hand configuration in `projectstate-spec.k` matches the reached
   final configuration. Transitivity composes the constructor branch rewrite
   with the finish rewrite.

## Adequacy

The formal English paraphrase in `fvk/FORMAL_SPEC_ENGLISH.md` is checked
against `fvk/INTENT_SPEC.md` in `fvk/SPEC_AUDIT.md`. All obligations pass.
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` records the intentional external
compatibility change and the source callsite check.

## Commands To Machine-Check Later

These commands were not run here:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/projectstate-spec.k
kprove fvk/projectstate-spec.k
```

Expected result after installing/configuring K: `kprove` returns `#Top`.

## Test Recommendation

No test files were modified. Because the proof is constructed but not
machine-checked, no test removal is recommended. Existing tests that exercise
`ProjectState(real_apps=...)` should be kept unless the K proof is later
machine-checked and the project maintainers explicitly choose to use the proof
to subsume point tests.

