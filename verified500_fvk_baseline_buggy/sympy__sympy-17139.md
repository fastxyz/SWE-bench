# sympy__sympy-17139

## Summary

**Severity:** Low — baseline silently rewrites odd perfect-power trig exponents
under `pow=True` (e.g. `sin(x)**9`) and can pass a symbolic integer exponent into
`perfect_power()`, but only in the specialized `pow=True` simplification mode, so
the practical blast radius is narrow.

Both arms passed the official SWE-bench evaluation for issue #17139, and the FVK
patch is a **strict superset** of the baseline patch: it keeps baseline's
non-integer entry guard and adds two further guards inside the `pow=True` branch.
The residual defect is minor; the case matters because FVK located it by
**formalizing the docstring's `pow=True` contract as an invariant and auditing the
`perfect_power` call against it** — not by running more tests.

| Arm | `_TR56(sin(x)**9, …, pow=True)` and `simplify(cos(x)**I)` | Resolved |
|---|---|---|
| baseline | `cos(x)**I` fixed; `sin(x)**9` still rewritten (residual) | partial |
| gold (human oracle) | reported crash fixed | n/a for residual |
| **fvk** | both the crash and the `pow=True` domain gap closed | yes |

## 1. The issue and the real defect

**Issue #17139** — `simplify(cos(x)**I)` raises `TypeError: Invalid comparison of
complex I` instead of leaving the expression unchanged
([`prompts/fvk.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/prompts/fvk.md#L2)).

The crash originates in `_TR56` in `sympy/simplify/fu.py`, the helper that `TR5`,
`TR6`, `TR15`, `TR16`, and `TR22` share to rewrite even-integer trig powers such
as `cos(x)**2` via Pythagorean identities. Its first action is `rv.exp < 0`, an
ordered comparison that is only valid for real values; with `rv.exp == I` it
raises before the rule can decide to leave the power alone
([`reports/baseline_notes.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/reports/baseline_notes.md#L4)).

Beyond the reported crash, `_TR56` documents a second contract that the original
code under-enforces: with `pow=True` the exponent must be a power of two — the
docstring's own example says `f**6` is unchanged but `f**8` is changed
([`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9)).
The `pow=True` branch reaches that decision through `perfect_power(rv.exp)`, which
succeeds for *any* perfect power, not only powers of two.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/solutions/solution_baseline.patch)
added one early guard that returns the expression unchanged unless the exponent is
a known integer:

```python
if rv.exp.is_integer is not True:
    return rv
```

This is a clean fix for the reported crash: a complex exponent like `I` is not a
known integer, so it exits before any ordered comparison. Baseline's notes show
the choice was deliberate — it explicitly weighed and *rejected* the stricter
`rv.exp.is_Integer` predicate:

> *"Another option was to require `rv.exp.is_Integer`, which would accept only
> literal integer exponent objects. I rejected that as unnecessarily restrictive
> because other parts of `fu.py` use assumption predicates like `is_integer` to
> support symbolic integer exponents where possible."*
> — [`reports/baseline_notes.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/reports/baseline_notes.md#L45)

That reasoning is right for the *entry* guard but leaves the `pow=True` branch
under-protected. By admitting symbolic integers at the top, baseline lets a
symbolic integer exponent flow into `perfect_power()` (which requires a concrete
integer via `as_int`), and its `if not p: return rv` acceptance test rewrites any
perfect power, including odd ones like `9` that are not powers of two. Baseline
fixed the entry but left the `pow=True` precondition unmet.

## 3. How FVK formally captured the gap

FVK started from the helper's documented contract, not the crash symptom. The
decisive intent item lifts the docstring's `pow=True` rule into an invariant:

> *"With `pow=True`, only exponents expressible as powers of two may be rewritten.
> Non-powers of two and undecidable symbolic integer exponents remain unchanged."*
> — [`fvk/INTENT_SPEC.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/INTENT_SPEC.md#L16)

The evidence ledger pins that intent to two concrete code facts found by source
audit — the docstring example and the `perfect_power` precondition — not to the
reported test:

> **E5:** *"`f**6 will not be changed but f**8 will be changed`"* → *6 is a
> non-power-of-two example; 8 is a power-of-two example.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9)

> **E8:** *"`ValueError is raised if n is not an integer or is not positive`;
> implementation calls `as_int(n)`"* → *Do not call `perfect_power` on symbolic
> integer exponents that are not concrete integers.*
> — [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PUBLIC_EVIDENCE_LEDGER.md#L12)

These discharge into one proof obligation that the entry-guard fix does not cover:

> **PO-6 — `pow=True` Rewrites Only Concrete Powers of Two.** *non-concrete
> symbolic integer exponents are unchanged before `perfect_power`; … the rewrite
> is allowed only when `perfect_power(rv.exp)` succeeds with base `2`; … all
> concrete non-powers of two, including `6` and `9`, are unchanged.*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PROOF_OBLIGATIONS.md#L46)

This is the crux: the residual defect was located by **reasoning against the
helper's own contract**, not by observation. The crash is captured by PO-1
([`fvk/PROOF_OBLIGATIONS.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PROOF_OBLIGATIONS.md#L5));
the audit then asked what *else* the `is_integer` entry guard fails to enforce,
and PO-6 names exactly the `pow=True` cases the baseline left open.

## 4. From formal output to the fix

The FVK arm audited the V1 (baseline-equivalent) fix and recorded the precise step
where the formalism extended the patch.

- The completeness audit raised a two-part finding against the `pow=True` branch:

  > **F2: V1 Left a `pow=True` Domain Gap in `_TR56`.** *`perfect_power(9)`
  > succeeds even though `9` is not a power of two. V1 would choose `e = 9//2` and
  > rewrite an odd power as `h(cos(x)**2)**4`, dropping one factor of `sin(x)`.*
  > — [`fvk/FINDINGS.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/FINDINGS.md#L19)

- The iteration guidance turned F2/PO-6 into concrete instructions:

  > *"Add a concrete-`Integer` guard inside the `pow=True` branch before calling
  > `perfect_power` … Require `perfect_power(rv.exp)` to return base `2` before
  > allowing a `pow=True` rewrite. This is justified by F2 and PO-6."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/ITERATION_GUIDANCE.md#L10)

- The decision log records the resulting two code changes and their provenance:

  > *"I added a concrete-`Integer` guard in the `pow=True` branch … I changed the
  > `perfect_power` acceptance check from `if not p: return rv` to
  > `if not p or p[0] != 2: return rv` … PO-6 requires concrete non-powers of two
  > to remain unchanged."*
  > — [`reports/fvk_notes.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/reports/fvk_notes.md#L17)

The causal chain is fully on the record:

```
INTENT_SPEC #6  ->  E5/E8 (code audit: docstring power-of-2 rule + perfect_power as_int precondition)
                ->  F2    (V1 audit: symbolic int reaches perfect_power; odd perfect powers rewritten)
                ->  PO-6  (obligation: pow=True only rewrites concrete powers of two)
                ->  ITERATION_GUIDANCE / fvk_notes  ->  fvk patch (two added guards)
```

The [FVK patch](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/solutions/solution_fvk.patch#L18)
keeps baseline's entry guard verbatim and adds the two `pow=True` guards:

```python
else:
    if not rv.exp.is_Integer:
        return rv
    p = perfect_power(rv.exp)
    if not p or p[0] != 2:
        return rv
```

The extension from baseline to FVK was driven by `F2`/`PO-6`, **not** by a new
failing test — the run forbade executing or adding any test
([`fvk/FINDINGS.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/FINDINGS.md#L44)).

## 5. Verification

**Source-and-artifact reviewed; not executed.** This case is `proof=no` with no
harness RED/GREEN reports and no executed demonstration table; the verification is
by inspection of the patches and FVK artifacts.

- **Patch delta confirmed.** `diff solution_baseline.patch solution_fvk.patch`
  shows the FVK patch is a strict superset: identical first hunk
  (`rv.exp.is_integer is not True` entry guard) plus a second hunk adding
  `if not rv.exp.is_Integer: return rv` and tightening the acceptance test to
  `if not p or p[0] != 2`
  ([`solutions/solution_fvk.patch`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/solutions/solution_fvk.patch#L18)).
- **Behavior argued, not run.** The `pow=True` reasoning is statically derived in
  the artifacts: with the new guards, a symbolic integer exponent exits before
  `perfect_power`, and `perfect_power(9) = (3, 2)` fails the `p[0] != 2` check so
  `sin(x)**9` is left unchanged — matching the docstring's `f**6`/`f**8` examples
  ([`fvk/FINDINGS.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/FINDINGS.md#L34)).
- **Constructed K core, not machine-checked.** The K claims
  ([`fvk/mini-sympy-fu.k`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/mini-sympy-fu.k),
  [`fvk/tr56-spec.k`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/tr56-spec.k))
  and the `kompile`/`kprove` commands were written but never run; the artifacts
  say so explicitly
  ([`fvk/PROOF.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PROOF.md#L3)).

**Comparison to the human oracle (no gold file in this non-curated run).** The
reported issue's fix only needs to stop the `cos(x)**I` crash; the gold/upstream
fix is scoped to that crash. FVK's two extra `pow=True` guards address a separate
contract gap the reported issue never exercises, so this is an over-fix relative
to what the issue required, justified entirely by the docstring contract rather
than by a failing test.

## 6. Boundaries & honesty

- **Severity: Low.** The residual defect lives only in `_TR56`'s `pow=True`
  branch with an odd-perfect-power or symbolic-integer exponent (e.g.
  `sin(x)**9`). `pow=True` is a specialized simplification mode and these
  exponents are uncommon, so the trigger breadth is narrow. The value demonstrated
  is **detection power and contract completeness**, not impact magnitude.
- **Proof status: constructed, not machine-checked.** We claim proof-structured
  reasoning (a formal spec with PO-1…PO-8 discharged by construction over a small
  K model), **not** a machine-checked proof — `kprove` was not run
  ([`fvk/PROOF.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PROOF.md#L47)).
  The artifacts also note the proof is partial and rests on the abstraction that
  `perfect_power(n)` with base `2` exactly models "n is a power of two"
  ([`fvk/PROOF.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PROOF.md#L65)).
- **Verification gap.** No test was added or executed; the `sin(x)**9`-unchanged
  and symbolic-integer behaviors are argued from the patch and findings, not
  observed. A reviewer should run `_TR56(sin(x)**9, sin, cos, h, 10, True)` and
  `simplify(cos(x)**I)` to confirm.
- **Consistency with the prior doc.** The earlier evidence doc's claims — baseline
  fixes the crash, FVK additionally guards the `pow=True` branch against symbolic
  integers and odd perfect powers — match the patches and `FINDINGS.md` F2; no
  contradiction was found, so nothing was corrected beyond restructuring.

## Artifact map

| Claim | Source |
|---|---|
| Issue / task statement | [`prompts/fvk.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/prompts/fvk.md#L2) |
| Crash root cause (`rv.exp < 0` on `I`) | [`reports/baseline_notes.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/reports/baseline_notes.md#L4) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/solutions/solution_baseline.patch) |
| Baseline rejected `is_Integer` | [`reports/baseline_notes.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/reports/baseline_notes.md#L45) |
| FVK patch (strict superset) | [`solutions/solution_fvk.patch`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/solutions/solution_fvk.patch#L18) |
| Intent: `pow=True` powers-of-two only | [`fvk/INTENT_SPEC.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/INTENT_SPEC.md#L16) |
| Evidence E5 (docstring `f**6`/`f**8`) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PUBLIC_EVIDENCE_LEDGER.md#L9) |
| Evidence E8 (`perfect_power` as_int) | [`fvk/PUBLIC_EVIDENCE_LEDGER.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PUBLIC_EVIDENCE_LEDGER.md#L12) |
| Obligation PO-1 (crash guard) | [`fvk/PROOF_OBLIGATIONS.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PROOF_OBLIGATIONS.md#L5) |
| Obligation PO-6 (`pow=True` domain) | [`fvk/PROOF_OBLIGATIONS.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PROOF_OBLIGATIONS.md#L46) |
| Finding F2 (`pow=True` gap, `9`) | [`fvk/FINDINGS.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/FINDINGS.md#L19) |
| No test executed (F3) | [`fvk/FINDINGS.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/FINDINGS.md#L44) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/ITERATION_GUIDANCE.md#L10) |
| Decision trace (two added guards) | [`reports/fvk_notes.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/reports/fvk_notes.md#L17) |
| SPEC contract + intent ledger | [`fvk/SPEC.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/SPEC.md#L28) |
| Constructed K core | [`fvk/mini-sympy-fu.k`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/mini-sympy-fu.k), [`fvk/tr56-spec.k`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/tr56-spec.k) |
| Proof constructed, not run | [`fvk/PROOF.md`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/fvk/PROOF.md#L3) |
| Raw model traces | [`transcripts/`](../results/verified046-codex-wsl-ubuntu-260615221107/sympy__sympy-17139/transcripts/) |
