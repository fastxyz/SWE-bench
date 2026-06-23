# astropy__astropy-14539

## Summary

**Severity:** High — baseline's variable-length-array (VLA) row predicate uses raw
`np.allclose`, which silently returns the wrong FITS-table diff answer for
differently-shaped rows and for floating rows holding matching invalid values.

Baseline correctly extended the FITS VLA diff path to `Q` descriptors, killing the
reported false-positive family. The residual defect is in the *comparison predicate*
it reused: `np.allclose` does not encode row shape and does not follow FITSDiff's
established invalid-floating-value policy. FVK located this by formalizing what "row
equality" must mean for a VLA row and auditing the predicate against that contract,
then added `_vla_values_differ`.

| Arm | VLA row equality predicate | Resolved (full contract) |
|---|---|---|
| baseline | raw `np.allclose` (no shape, no invalid-value policy) | no |
| **fvk** | `_vla_values_differ` (shape → `where_not_allclose` → `allclose` → exact) | yes |

## 1. The issue and the real defect

The issue: `io.fits.FITSDiff` can report differences between **identical** files —
comparing a file to itself should never yield a difference — and the reproducer uses
a `QD`-format VLA column, which "only `P` is handled in the diff code"
([`fvk/PUBLIC_EVIDENCE_LEDGER.md` E-001…E-004](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/PUBLIC_EVIDENCE_LEDGER.md#L5)).

`TableDataDiff._diff` had a row-wise comparison path for VLA columns but recognized
only `P`-format descriptors; `Q`-format VLA columns fell through to the generic
`np.where(arra != arrb)`, which marks object-array rows of variable-length ndarrays
as different even when identical
([`reports/baseline_notes.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/reports/baseline_notes.md#L5)).

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/solutions/solution_baseline.patch)
made the VLA branch treat both `P` and `Q` as variable-length arrays, routing `Q`
columns through the existing **row-wise `np.allclose`** comparison:

> *These columns now use the existing row-wise `np.allclose` comparison, which*
> *compares the actual per-row array contents and preserves the existing tolerance*
> *behavior for numeric VLA data.*
> — [`reports/baseline_notes.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/reports/baseline_notes.md#L18)

That dispatch decision is correct and is what made the reported case pass. But
baseline reused `np.allclose` as the *complete* row predicate. The unmet obligation:
`np.allclose` is not a shape-equality test, and it does not follow FITSDiff's own
invalid-value comparison policy — so a row can be classified equal or different under
the wrong rule.

## 3. How FVK formally captured the gap

The intent spec states up front what VLA row equality must include — written before
accepting any candidate behavior:

> *5. For VLA row values, row shape is part of row equality.*
> *6. Floating row values should follow FITSDiff's existing floating comparison*
> *policy, including tolerance and matching invalid-value handling.*
> — [`fvk/INTENT_SPEC.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/INTENT_SPEC.md#L13)

The evidence ledger pins clause 6 to a concrete code fact found by **source audit** —
the existing FITSDiff helper and its test contract — not to the reported reproducer:

> **E-006:** *`repo/astropy/utils/diff.py` — `where_not_allclose` handles invalid*
> *floating values → Floating VLA rows should use the same policy.*
> **E-007:** *`repo/.../tests/test_diff.py` — `test_diff_nans` expects matching NaNs to*
> *be identical → Matching invalid floating values are not differences.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10)

Those discharge into formal obligations the baseline predicate does not satisfy:

> **PO-003:** *VLA row length/shape is part of row content equality; different shapes*
> *must be reported different.* … **PO-004:** *Floating VLA rows must follow FITSDiff's*
> *invalid-floating-value policy.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/PROOF_OBLIGATIONS.md#L9)

The gap was located by reasoning: the issue is about dispatch (`P` vs `Q`), but the
spec generalizes "no false differences" into a full row-equality contract, and the
audit shows raw `np.allclose` violates two clauses of it regardless of dispatch.

## 4. From formal output to the fix

The completeness audit against the spec produced the finding that flipped the patch:

> **F-002 — V1 row predicate was too weak for the full VLA contract.** *the VLA branch*
> *used raw `np.allclose`, while the established FITSDiff floating-array helper is*
> *`where_not_allclose` … raw numeric closeness is not a shape-equality predicate.*
> — [`fvk/FINDINGS.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/FINDINGS.md#L22)

The iteration guidance turned that into an explicit code instruction:

> *V1 should not stand unchanged. F-002 showed that V1 fixed the reported `Q` … source*
> *was revised to add `_vla_values_differ` and to call it from the `P`/`Q` … branch.*
> — [`fvk/ITERATION_GUIDANCE.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/ITERATION_GUIDANCE.md#L7)

And the decision trace records the resulting helper and its provenance:

> *F-002 … maps to PROOF_OBLIGATIONS PO-003 and PO-004. I added `_vla_values_differ`*
> *to check shape first, use `where_not_allclose` for floating rows, preserve*
> *`np.allclose` for [non-floating numeric] … per PO-005 and PO-006.*
> — [`reports/fvk_notes.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/reports/fvk_notes.md#L5)

```
INTENT 5/6  ->  E-006/E-007 (audit: where_not_allclose is the FITSDiff floating policy)
            ->  F-002 (V1 audit: raw np.allclose ignores shape + invalid-value policy)
            ->  PO-003 / PO-004
            ->  ITERATION_GUIDANCE / fvk_notes  ->  add _vla_values_differ
```

The [FVK patch](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/solutions/solution_fvk.patch)
adds the helper and routes the VLA row loop through it:

```python
def _vla_values_differ(a, b, rtol=0.0, atol=0.0):
    a = np.asanyarray(a); b = np.asanyarray(b)
    if a.shape != b.shape:
        return True
    if np.issubdtype(a.dtype, np.floating) and np.issubdtype(b.dtype, np.floating):
        return len(where_not_allclose(a, b, rtol=rtol, atol=atol)[0]) > 0
    if np.issubdtype(a.dtype, np.number) and np.issubdtype(b.dtype, np.number):
        return not np.allclose(a, b, rtol=rtol, atol=atol)
    return bool(np.any(a != b))
```

The `Q`-dispatch fix from V1 was kept (F-001/PO-001); the predicate upgrade was
driven by the formal completeness finding F-002, **not** by a new failing test.

## 5. Verification

**Source-and-artifact reviewed; not executed.** This run is not on the harness
(`proof=no`) and is not curated, so there is no RED/GREEN report and no executed
demonstration. What was inspected:

- The FVK patch vs baseline patch (`diff`): confirms baseline reused row-wise
  `np.allclose`, and FVK replaced the predicate with `_vla_values_differ`.
- `fvk/PROOF_OBLIGATIONS.md` PO-003…PO-006: the four row-equality cases (shape,
  floating-with-policy, non-floating numeric, non-numeric) are each mapped to a
  branch of the helper.
- The predicate failure classes are stated as static reasoning in F-002 (matching
  invalid floats wrongly flagged; differently-shaped rows compared by value). They
  are argued, not executed here.

Both arms passed the official SWE-bench evaluation; the residual is outside the
public test set (see §6).

## 6. Boundaries & honesty

- **Severity: High.** The failure mode is a *silent wrong answer* from a diff tool,
  not an exception. FITSDiff reporting that two FITS tables match or differ under the
  wrong VLA predicate returns incorrect scientific-data metadata to the caller, and
  the trigger (any differently-shaped VLA rows, or floating VLA rows with matching
  invalid values) is reachable through ordinary FITS comparison.
- **Evidence is static, not executed.** The residual-bug claim rests on reading the
  predicate and the FITSDiff invalid-value policy (E-006/E-007), plus F-002's static
  case analysis. No demonstration was run in this environment, so this is reasoned
  evidence of the gap, not an observed failure.
- **Why the tests missed it.** The public reproducer and PASS set exercise `Q`
  dispatch and self-comparison, not differently-shaped VLA rows or matching invalid
  floats — so baseline scores "resolved" while the predicate gap stays untested.
- **Proof status: constructed, not machine-checked.** No `kompile`/`kprove` were run
  ([`fvk/PROOF.md`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/PROOF.md#L3)).
  Claim cited as proof-structured reasoning.

## Artifact map

| Claim | Source |
|---|---|
| Issue (identical files differ; `QD`; only `P`) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L5`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/PUBLIC_EVIDENCE_LEDGER.md#L5) |
| Baseline root cause (`Q` fell through) | [`reports/baseline_notes.md#L5`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/reports/baseline_notes.md#L5) |
| Baseline reused `np.allclose` | [`reports/baseline_notes.md#L18`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/reports/baseline_notes.md#L18) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/solutions/solution_baseline.patch) |
| Intent clauses 5/6 (shape + policy) | [`fvk/INTENT_SPEC.md#L13`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/INTENT_SPEC.md#L13) |
| Evidence E-006/E-007 (code audit) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md#L10`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/PUBLIC_EVIDENCE_LEDGER.md#L10) |
| Obligations PO-003/PO-004 | [`fvk/PROOF_OBLIGATIONS.md#L9`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/PROOF_OBLIGATIONS.md#L9) |
| Finding F-002 | [`fvk/FINDINGS.md#L22`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/FINDINGS.md#L22) |
| Iteration instruction | [`fvk/ITERATION_GUIDANCE.md#L7`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/ITERATION_GUIDANCE.md#L7) |
| Decision trace (`_vla_values_differ`) | [`reports/fvk_notes.md#L5`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/reports/fvk_notes.md#L5) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/solutions/solution_fvk.patch) |
| Proof not machine-checked | [`fvk/PROOF.md#L3`](../results/verified002-codex-XC-MINI-PRO-AHP-20260615T143019Z/astropy__astropy-14539/fvk/PROOF.md#L3) |
