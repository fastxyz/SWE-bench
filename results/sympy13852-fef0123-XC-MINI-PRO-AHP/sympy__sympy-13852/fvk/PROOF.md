# PROOF.md — constructed correctness proof for the polylog fix

**Constructed, not machine-checked.** Symbolic execution against
[`mini-sympy.k`](mini-sympy.k); claims in [`polylog-spec.k`](polylog-spec.k).
Run-commands:

```sh
kompile mini-sympy.k --backend haskell      # compile the fragment semantics
kast    --backend haskell polylog-spec.k    # (optional) confirm the claims parse
kprove  polylog-spec.k                       # discharge; expected: #Top (all proved)
```

Notation: `DILOG ≜ pi ^ 2 / 12 − log(2) ^ 2 / 2`. `=>` is a single rewrite step;
`=>*` its transitive closure. The unit has no loop, so no circularity is needed;
each proof is a finite rewrite sequence composed by Transitivity, with cells
framed automatically.

---

## §A — PO-1 (EVAL-DILOG): `polylog(2, half) =>* DILOG`

```
<k> polylog(2, half) </k>
  => <k> pi ^ 2 / 12 − log(2) ^ 2 / 2 </k>      [eval-dilog]      // = DILOG
```
One step; the RHS is a normal form (no rule matches `pi`, `log(2)`, or the
arithmetic constructors). ∎ Matches the claim's post-state.

## §B — PO-2 (SIMPLIFY-R18): `simplify(Li2sum_half) =>* DILOG`  (the discriminator)

`simplify` is `strict`, so its argument is reduced first:

```
<k> simplify(Li2sum_half) </k>
  => <k> simplify(polylog(2, half)) </k>        [doit-sum]   (heating the argument)
  => <k> simplify(DILOG) </k>                   [eval-dilog] (argument now a value)
  => <k> DILOG </k>                             [simplify-noexpand]
```
∎ Reaches the post-state.

**Adversarial reproduction of the bug on the pre-fix (V1) semantics.** Delete
`eval-dilog`; keep V1's `expand(polylog(2,half)) => DILOG`. Re-run:

```
<k> simplify(Li2sum_half) </k>
  => <k> simplify(polylog(2, half)) </k>        [doit-sum]
  -- no eval rule matches polylog(2, half); strictness completes with the value
  => <k> polylog(2, half) </k>                  [simplify-noexpand]   // STUCK ≠ DILOG
```
The normal form is `polylog(2, half) ≠ DILOG`, so PO-2 is **underivable under
V1**. This is the pointed-at-the-spot localization: the symptom in `test_R18`
(`.doit().simplify()` not reaching the value) is *generated* by the absence of a
construction-path rule, **not** by anything in `_eval_expand_func` — `simplify`
never calls `expand_func` (`simplify.py:556–620`). V2's one added `eval` line is
exactly what makes §B go through. This is the proof that **V1 was wrong**, and
that the wrongness is on the construction path, where V1 declined to place the
value.

## §C — PO-3 (EXPAND-DILOG): `expand(polylog(2, half)) =>* DILOG`  (no regression)

```
<k> expand(polylog(2, half)) </k>
  => <k> expand(DILOG) </k>                      [eval-dilog]  (strict arg reduces)
  => <k> DILOG </k>                              [expand-id]   (isPolylog(DILOG)=false)
```
∎ The issue's `.expand(func=True)` surface still yields the value — now because
construction reduced the object and `expand_func` is the identity on the result.

## §D — PO-4 (EXPAND-LOG1) + PO-5 (DERIV-CONSISTENT)

```
<k> expand(polylog(1, Z)) </k>
  -- VC-FREEVAR: Z symbolic ⇒ Z ∉ {0,1,neg(1)} and 1≠2 ⇒ no eval rule fires
  => <k> neg(log(1 − Z)) </k>                    [expand-log1]
```
∎ Post-state reached; the result carries **no** `exp_polar` factor (the rule's
RHS does not contain it). Contrast V1's RHS `neg(log(1 + exp_polar(neg(I*pi))*Z))`.

PO-5 (VC-DERIV, discharged in first-order arithmetic outside the fragment):
`d/dz[−log(1−z)] = 1/(1−z)`. `d/dz[polylog(1,z)] = polylog(0,z)/z`, and
`expand_func(polylog(0,z)) = z/(1−z)` ⇒ `polylog(0,z)/z = 1/(1−z)`. Hence
`d/dz[polylog(1,z) − (−log(1−z))] = 1/(1−z) − 1/(1−z) = 0`. ✅ (Under V1 the
subtrahend's derivative is `−exp_polar(−Iπ)/(1+exp_polar(−Iπ)z)`, which does
**not** cancel — exactly the prompt's complaint.)

## §E — PO-6 (NO-BREAKAGE)

`eval-dilog` has the closed pattern `polylog(2, half)`; it cannot match any
`polylog(S, Z)` unless `S=2 ∧ Z=half`. For every other in-domain pair the
applicable rules are exactly V1's (`eval-z0`, `eval-z1`, `eval-zm1`, or none →
inert `polylog(S,Z)`), so their normal forms are unchanged. Cross-checked against
the corpus: `polylog(x,y)` / `polylog(2,z)` with symbolic args do not match
`half`. ∎

## §F — Residual trust / honesty gate

- **Constructed, not machine-checked** — `kprove` not run here.
- **Fragment adequacy.** `mini-sympy.k` abstracts SymPy's real evaluator. The one
  property it must preserve — *which evaluation paths collapse `polylog(2,1/2)`* —
  is kept observable, and the V1/V2 split in §B shows the model is discriminating
  (a passing and a failing instance do **not** collapse to the same observable).
- **VC-VALUE caveat.** The closed form is treated as an opaque term; the model
  does not execute `simplify`'s `together()/shorter()` re-association. The risk
  that `simplify` reorders `DILOG` into a different *structural* form is argued
  away in ITERATION_GUIDANCE (the str form `-log(2)**2/2 + pi**2/12` is the one
  `print()` emits per PROBLEM.md line 14, and is what `test_R18` asserts with
  `==`); this is residual trust, not proved here.
- **Partial correctness** — termination of the rewrite system is immediate (each
  rule shrinks the term) and not the object of proof.

## Benefit payoffs

1. **Bug found (benefit 2).** Writing PO-2 made the spec *impossible to discharge
   under V1*: the value the issue wants is unreachable through `.doit().simplify()`
   when it lives only in `expand_func`. That difficulty **is** the finding —
   V1 misfiled the value (see FINDINGS F1).
2. **Tests (benefit 1).** Once `kprove` returns `#Top`, EVAL-DILOG and SIMPLIFY-R18
   subsume the in-domain point checks for `polylog(2,1/2)` (test-redundancy in
   ITERATION_GUIDANCE). Out-of-domain / symbolic tests are **kept**.
