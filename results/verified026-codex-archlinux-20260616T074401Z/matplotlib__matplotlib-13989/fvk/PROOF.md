# Constructed Proof

Status: constructed, not machine-checked.

This proof audits the V1 fix to `Axes.hist` kwargs construction. It has not
been run through `kompile` or `kprove`.

## Formal artifacts

- Semantics: `fvk/mini-hist-kwargs.k`
- Claims: `fvk/hist-kwargs-spec.k`
- Spec note: `fvk/SPEC.md`
- Proof obligations: `fvk/PROOF_OBLIGATIONS.md`

## Reproduce the machine check later

Do not run these commands in this benchmark session. They are recorded for a
future environment with K installed.

```sh
cd fvk
kompile mini-hist-kwargs.k --backend haskell -d .kbuild/hist-kwargs
kast --definition .kbuild/hist-kwargs hist-kwargs-spec.k
kprove hist-kwargs-spec.k --definition .kbuild/hist-kwargs
```

Expected result after machine checking: `#Top` for all claims.

## Proof sketch

### PO-001 / claim `hist-range-density`

Start state:

```text
buildHistKwargs(false, 1, range(lo, hi), true, false, false)
```

Symbolic execution applies the main rule:

```text
addDensity(initKwargs(false, 1, range(lo, hi)),
           effectiveDensity(true, false),
           false)
```

`initKwargs(false, 1, R)` takes the single-dataset path and returns:

```text
kw(true, R, false, false)
```

`effectiveDensity(true, false)` rewrites to `true`. Since `stacked=False`,
`addDensity` rewrites:

```text
kw(true, R, false, false) -> kw(true, R, true, true)
```

Substituting `R = range(lo, hi)` gives the postcondition. Range is preserved
because `addDensity` carries the `hasRange` and `rangeValue` fields unchanged.

### PO-002 / claim `hist-range-no-density`

`initKwargs(false, 1, R)` returns `kw(true, R, false, false)`.
`effectiveDensity(false, false)` rewrites to `false`, so `addDensity` returns
the kwargs unchanged. This proves the non-density frame condition.

### PO-003 / claim `hist-stacked-frame`

`initKwargs(false, 1, R)` returns `kw(true, R, false, false)`.
`effectiveDensity(true, false)` rewrites to `true`, but because
`stacked=True`, `addDensity` returns the kwargs unchanged. This proves that
stacked density remains manually normalized later and is not converted into
per-dataset NumPy density normalization.

### PO-004 / claim `hist-multi-density-frame`

For `inputEmpty=False` and `nx=2`, `initKwargs` takes the multi-dataset branch
and returns `kw(false, noRange, false, false)`. This models the source path
where common bins have already been computed with `histogram_bin_edges`.
Effective density is true and `stacked=False`, so `addDensity` returns
`kw(false, noRange, true, true)`. This preserves density without incorrectly
adding a range kwarg to the later per-dataset histogram calls.

### PO-005 / claim `hist-range-normed`

This follows the same steps as PO-001 except
`effectiveDensity(false, true)` rewrites to `true`. The final kwargs are
`kw(true, R, true, true)`.

## Adequacy and compatibility

The formal English paraphrase of each claim passes the intent audit in
`fvk/SPEC_AUDIT.md`. No public API or override compatibility blocker was
found in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## Test redundancy recommendation

No existing public test was identified as safe to remove. Existing histogram
tests cover rendering, image output, unequal-bin density values, stacked
density integration, and scale integration that this mini-proof does not fully
model.

After machine-checking, a focused unit test that only asserts the kwargs-level
range/density routing would be subsumed. A user-facing regression test of
returned bins for `plt.hist(..., bins='auto', range=(0, 1), density=True)`
should still be kept as integration coverage because it exercises NumPy
interoperation and the public return value.

## Honesty gate

This is a constructed proof only. It should not be treated as machine-verified
until the recorded `kompile` and `kprove` commands are run successfully in an
environment with K installed.
