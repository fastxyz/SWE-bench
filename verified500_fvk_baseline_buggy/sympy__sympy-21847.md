# sympy__sympy-21847

## Summary

**Severity:** Low — baseline's `itermonomials` fix still yields the unit monomial `1`
for empty variables when `min_degree > 0`, but only on the empty-variable boundary, so
the practical blast radius is small.

Baseline and FVK both passed the official SWE-bench evaluation for this issue, with
**different** patches. Baseline correctly replaced the lower-bound filter
(`max(powers.values())` → `sum(powers.values())`) for populated candidates but left one
residual contract violation: the early unit-monomial branch yields `1` even when the
caller asked for a positive total-degree minimum, where `1` (total degree `0`) is out of
range. FVK located that boundary by **formalizing the total-degree postcondition as an
invariant over every yield site** — not by running more tests — and added a one-line
`min_degree == 0` guard.

| Arm | Empty-variable boundary `itermonomials([], 2, 1)` | Resolved |
|---|---|---|
| baseline | yields `1` (out of range) | no |
| gold (human oracle) | yields `1` (out of range) | no |
| **fvk** | yields nothing (correct) | **yes** |

## 1. The issue and the real defect

The reported issue is that `itermonomials` returns *incorrect monomials when using the
optional `min_degrees` argument* and should also return mixed monomials such as
`x1*x2**2` and `x2*x3**2`
([`prompts/fvk.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/prompts/fvk.md#L12)).
The documented integer-mode contract is `min_degree <= total_degree(monom) <= max_degree`.

`sympy.polys.monomials.itermonomials` generates monomials of total degree up to
`max_degree` by padding `combinations_with_replacement` / `product` with `S.One`, then
filters by the lower bound. The reported root cause is that the lower-bound filter used
`max(powers.values())` — the largest single-variable exponent — instead of the *total*
degree, so a mixed monomial like `x1*x2**2` (largest exponent `2`, total degree `3`) was
rejected at `min_degree = 3`
([`reports/baseline_notes.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/reports/baseline_notes.md#L7)).

There is a second yield site upstream of that filter — the early branch that short-circuits
for an empty variable list or `max_degree == 0`:

```python
if not variables or max_degree == 0:
    yield S.One
    return
```

`S.One` has total degree `0`. This branch yields it **unconditionally**, so for
`itermonomials([], 2, 1)` it emits `1` even though the caller's lower bound is `1` and
`total_degree(1) = 0` is out of range.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/solutions/solution_baseline.patch)
applied the fix the issue itself hints at — replacing `max(powers.values())` with
`sum(powers.values())` in **both** the commutative and non-commutative filter branches:

```python
-                if max(powers.values()) >= min_degree:
+                if sum(powers.values()) >= min_degree:
```

Baseline's reasoning is sound for the reported symptom and explicitly scopes itself to it:

> *"Changed both integer total-degree branches in `itermonomials` to use
> `sum(powers.values()) >= min_degree` … The same fix is applied to the commutative
> branch and the non-commutative branch."*
> — [`reports/baseline_notes.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/reports/baseline_notes.md#L13)

That repair is correct and is the same change gold and the upstream fix shipped. But
baseline only audited the *populated-candidate* filter. It never revisited the early
unit-monomial branch, which is the second place the function decides what to yield. So the
total-degree lower bound was now enforced for every monomial **except** the empty-variable
`1` — the obligation baseline left unmet.

## 3. How FVK formally captured the gap

FVK did not start from the symptom; it started from the documented postcondition and
applied it uniformly to every yield site. The intent spec states the lower bound as a
property of *every* yielded monomial:

> **I1.** *Integer `max_degrees` and `min_degrees` define total-degree bounds. For every
> yielded monomial `m`, `min_degree <= total_degree(m) <= max_degree`.*
> — [`fvk/INTENT_SPEC.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/INTENT_SPEC.md#L9)

and then derives the empty-variable corollary explicitly:

> **I5.** *The empty variable list has only the unit monomial `1`, whose total degree is
> `0`. … integer mode returns `1` for empty variables exactly when `min_degree == 0` …
> it returns no monomial when `min_degree > 0`.*
> — [`fvk/INTENT_SPEC.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/INTENT_SPEC.md#L17)

The evidence ledger pins that corollary to a concrete contract fact derived from the
docstring and public tests — **not** to the reported test:

> **E8.** *Empty variables have no positive-degree monomial. For `variables == []` and
> integer `min_degree > 0`, yielding `1` violates the total-degree lower bound.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/PUBLIC_EVIDENCE_LEDGER.md#L14)

which is discharged into a proof obligation over the unit branch:

> **PO-2 — Unit Monomial Boundary.** *When `variables` is empty or `max_degree == 0`,
> `S.One` is yielded iff `min_degree == 0`; otherwise no monomial is yielded.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/PROOF_OBLIGATIONS.md#L13)

This is the crux of FVK's value here: the residual bug was found by **applying the same
invariant to a yield site the reported test never touches**. The issue is about the
populated-candidate filter; FVK lifts it into a postcondition over *all* outputs (I1) and
the empty-variable boundary (I5/E8) falls out as a second obligation (PO-2) that baseline's
patch leaves unsatisfied.

## 4. From formal output to the fix

The FVK arm kept baseline's populated-candidate filter and added one guard, and the
artifacts record the exact step where the formalism changed the patch.

- The completeness audit against the spec raised the boundary finding:

  > **F2: V1 Still Yielded `1` for Empty Variables with Positive `min_degree`.** … *Input
  > `variables = []`, `max_degree = 2`, `min_degree = 1`. … Expected: no monomial, because
  > `total_degree(1) = 0` … Resolution: V2 changes the early unit-monomial branch to yield
  > `S.One` only when `min_degree == 0`.*
  > — [`fvk/FINDINGS.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/FINDINGS.md#L21)

- The iteration guidance turned the finding into a concrete instruction:

  > *"Add `if min_degree == 0` before yielding `S.One` when `not variables or
  > max_degree == 0`. Justified by F2 and PO-2."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/ITERATION_GUIDANCE.md#L13)

- The decision log records the change and traces it back to the finding and obligation:

  > *"Decision: change the early unit-monomial branch so `S.One` is yielded only when
  > `min_degree == 0`. … `FINDINGS.md` F2 surfaced a V1 gap: `itermonomials([], 2, 1)`
  > would yield `1` … PO-2 requires the unit monomial boundary to respect the lower bound.
  > The new guard discharges PO-2."*
  > — [`reports/fvk_notes.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/reports/fvk_notes.md#L17)

The causal chain is fully on the record:

```
INTENT I1  ->  I5 (empty-variable corollary of the total-degree bound)
           ->  E8 (ledger: yielding 1 for min_degree > 0 violates the bound)
           ->  PO-2 (obligation: unit branch yields 1 iff min_degree == 0)
           ->  F2 (V1 audit: empty-variable branch still yields 1)
           ->  ITERATION_GUIDANCE  ->  V2 guard
```

The resulting [FVK patch](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/solutions/solution_fvk.patch)
is baseline's two `max → sum` edits **plus** the new guard:

```python
         if not variables or max_degree == 0:
-            yield S.One
+            if min_degree == 0:
+                yield S.One
             return
```

The added guard was driven by the formal finding F2 / obligation PO-2, **not** by a new
failing test — no test for `itermonomials([], 2, 1)` exists in the suite (see §5), and the
task forbade adding one
([`fvk/FINDINGS.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/FINDINGS.md#L37)).

## 5. Verification

**Source-and-artifact reviewed; not executed.** This case is not on the curated harness
(no `enhanced_tests/_proof/` reports exist for it), and the only available test reports are
the official SWE-bench evaluations, which are **insensitive to the residual bug** — both
arms are `resolved: true` with identical `test_monomials` outcomes
([baseline](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/eval/baseline.report.json),
[fvk](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/eval/fvk.report.json))
because the official suite never exercises empty variables with a positive minimum. The
residual-bug claim therefore rests on review, not on an executed RED/GREEN.

What was inspected and the reasoning that supports the claim:

- **Patch delta.** `diff` of the two patches confirms FVK shipped baseline's two filter
  edits *plus* the `min_degree == 0` guard — the only code difference between the arms.
- **Behavioral argument.** For `itermonomials([], 2, 1)`: the `min_degree > max_degree`
  guard does not fire (`1 <= 2`), so control reaches `if not variables …`. Baseline/gold
  yield `S.One` (total degree `0`, below the requested minimum `1`); FVK's guard suppresses
  it and the generator yields nothing — matching obligation PO-2 and formal claim C5
  ([`fvk/FORMAL_SPEC_ENGLISH.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/FORMAL_SPEC_ENGLISH.md#L13)).
- **No regression.** The guard only narrows the empty-variable / `max_degree == 0` branch;
  the default `min_degrees=None` path (`min_degree = 0`) still yields `1`, so the public
  callsites that pass no `min_degrees` are unaffected
  ([`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L22)).

**FVK went beyond the human oracle.** Gold and the upstream fix changed only the
populated-candidate filter; neither added the empty-variable guard. FVK's extra fix
addresses a boundary that the maintainers' own patch left unrepaired.

## 6. Boundaries & honesty

- **Severity: Low.** The residual defect triggers only on the empty-variable (or
  `max_degree == 0`) boundary with a *positive* `min_degree` — an uncommon call shape — so
  the practical blast radius is small. The value demonstrated here is **detection power and
  completeness** (an invariant applied uniformly catches a yield site the reported test
  misses), not impact magnitude.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-monomials.k`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/mini-monomials.k),
  [`itermonomials-spec.k`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/itermonomials-spec.k))
  and the `kompile`/`kprove` commands were **written but never run** — the artifacts say so
  explicitly
  ([`fvk/PROOF.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/PROOF.md#L3),
  [`fvk/PROOF.md` command block](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/PROOF.md#L30)).
  We claim **proof-structured reasoning** (a total-degree spec with obligations discharged
  by construction), **not a machine-checked proof**. The mini-K model also abstracts the
  full Python generator, `itertools`, and SymPy expression canonicalization, a trusted
  boundary the run records as F4
  ([`fvk/FINDINGS.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/FINDINGS.md#L52)).
- **Verification caveat.** Because there is no test (curated or official) that distinguishes
  the arms on the empty-variable boundary, the residual-bug claim is **reviewed, not
  executed**. The behavioral argument in §5 is reconstructed from the source and patch
  delta, not observed from a run.
- **Discrepancy fixed from the prior doc.** The earlier evidence doc described `S.One` as
  the result of an "empty-variable" branch; the source shows the same branch also fires for
  `max_degree == 0`, and the FVK guard (PO-2 / I5) covers both. This is reflected above and
  matches the artifacts; no claim in the prior doc was contradicted by the run, only the
  branch condition was made precise.

## Artifact map

| Claim | Source |
|---|---|
| Issue text, problem statement | [`prompts/fvk.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/prompts/fvk.md#L12) |
| Reported root cause (`max` vs total degree) | [`reports/baseline_notes.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/reports/baseline_notes.md#L7) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/solutions/solution_baseline.patch) |
| Baseline reasoning (scoped to both filter branches) | [`reports/baseline_notes.md`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/reports/baseline_notes.md#L13) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/solutions/solution_fvk.patch) |
| Intent I1 (total-degree bound on every yield) | [`fvk/INTENT_SPEC.md#L9`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/INTENT_SPEC.md#L9) |
| Intent I5 (empty-variable corollary) | [`fvk/INTENT_SPEC.md#L17`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/INTENT_SPEC.md#L17) |
| Evidence E8 | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L14`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/PUBLIC_EVIDENCE_LEDGER.md#L14) |
| Obligation PO-2 (unit monomial boundary) | [`fvk/PROOF_OBLIGATIONS.md#L13`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/PROOF_OBLIGATIONS.md#L13) |
| Finding F2 (residual empty-variable bug) | [`fvk/FINDINGS.md#L21`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/FINDINGS.md#L21) |
| Test gap F3 (no test for the boundary) | [`fvk/FINDINGS.md#L37`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/FINDINGS.md#L37) |
| Abstraction boundary F4 | [`fvk/FINDINGS.md#L52`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/FINDINGS.md#L52) |
| Iteration instruction (add guard) | [`fvk/ITERATION_GUIDANCE.md#L13`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/ITERATION_GUIDANCE.md#L13) |
| Decision trace (V2 boundary fix) | [`reports/fvk_notes.md#L17`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/reports/fvk_notes.md#L17) |
| Formal claim C5 (unit branch yields 1 iff min 0) | [`fvk/FORMAL_SPEC_ENGLISH.md#L13`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/FORMAL_SPEC_ENGLISH.md#L13) |
| Compatibility (default path unaffected) | [`fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L22`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/PUBLIC_COMPATIBILITY_AUDIT.md#L22) |
| Official eval verdicts (insensitive to residual bug) | [`eval/baseline.report.json`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/eval/baseline.report.json), [`eval/fvk.report.json`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/eval/fvk.report.json) |
| Constructed K core | [`fvk/mini-monomials.k`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/mini-monomials.k), [`fvk/itermonomials-spec.k`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/itermonomials-spec.k) |
| Proof status (constructed, kprove not run) | [`fvk/PROOF.md#L3`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/PROOF.md#L3), [`fvk/PROOF.md#L30`](../results/verified049-codex-wsl-ubuntu-260615221107/sympy__sympy-21847/fvk/PROOF.md#L30) |
