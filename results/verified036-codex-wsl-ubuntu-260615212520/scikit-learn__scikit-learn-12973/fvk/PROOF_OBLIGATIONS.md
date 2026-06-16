# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Omitted fit copy_X honors the constructor

Claim: for all `C in {True, False}`, `fitRoute(C, None) = (C, C)`.

Intent evidence: E2 and E3 in `SPEC.md`.

Source evidence: `least_angle.py:1504-1508` resolves `copy_X is None` to `self.copy_X` before preprocessing, and `least_angle.py:1513-1515` passes the same local value to `lars_path`.

Finding linkage: closes F-001.

## PO-2: Explicit fit copy_X overrides consistently

Claim: for all `C in {True, False}` and `F in {True, False}`, `fitRoute(C, F) = (F, F)`.

Intent evidence: E4 and E5 in `SPEC.md`.

Source evidence: explicit boolean `copy_X` skips the `is None` branch and remains the local value used at both downstream callsites.

Finding linkage: closes F-002.

## PO-3: No mixed copy_X routing exists in-domain

Claim: for every in-domain argument pair, the two routed values are equal: `preprocess_copy == lars_path_copy`.

Intent evidence: E4 in `SPEC.md`.

Derivation: PO-1 returns `(C, C)` and PO-2 returns `(F, F)`, so equality holds for `None`, `True`, and `False` method values.

Finding linkage: closes F-001 and F-002.

## PO-4: Backward-compatible fit argument remains accepted

Claim: the method still has a third `copy_X` parameter and accepts explicit boolean values.

Intent evidence: E5 in `SPEC.md`.

Source evidence: `least_angle.py:1482` keeps `def fit(self, X, y, copy_X=None)`.

Finding linkage: supports rejecting the alternative of removing the fit argument.

## PO-5: Public documentation matches the accepted values

Claim: the fit docstring describes the accepted sentinel and its semantics.

Intent evidence: E2/E3 in `SPEC.md` plus public API documentation convention that documented parameter types include accepted sentinel values.

Source evidence: `least_angle.py:1493-1495` documents `boolean or None` and says `None` uses `self.copy_X`.

Finding linkage: closes F-003.

## PO-6: Honesty gate

Claim: proof status is constructed, not machine-checked; no tests or K commands were run; no test deletions are justified.

Intent evidence: task prohibition on execution and FVK honesty gate.

Finding linkage: records F-004.

## Constructed K Claims

The concrete K claim files are:

- `fvk/mini-copy-routing.k`
- `fvk/lasso-lars-ic-copy-x-spec.k`

Expected commands, not executed:

```sh
cd fvk
kompile mini-copy-routing.k --backend haskell
kast --backend haskell lasso-lars-ic-copy-x-spec.k
kprove lasso-lars-ic-copy-x-spec.k
```
