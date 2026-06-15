# FVK notes — auditing and improving the V1 fix for sympy 13852

This records every decision in the FVK pass, tracing each to entries in
[`fvk/FINDINGS.md`](../fvk/FINDINGS.md) and
[`fvk/PROOF_OBLIGATIONS.md`](../fvk/PROOF_OBLIGATIONS.md). All proof results are
**constructed, not machine-checked** (no execution environment).

## What the audit found, in one line

V1 was **half right**: the `exp_polar` removal (`expand_func(polylog(1, z)) =
-log(1 - z)`) was correct, but V1 placed the `polylog(2, 1/2)` value on the
**wrong path** — the opt-in `expand_func`, while the bare construction still
returned the unevaluated symptom. V2 moves that value to `eval`.

## The decisive finding (F1 / PO-1 / PO-2): placement was wrong

The FVK intent pass made me re-read the issue *as intent*, not as a transform
recipe. The issue's title is "Add **evaluation**", and the desired value
`-log(2)**2/2 + pi**2/12` is wanted for the **bare** object
`polylog(2, Rational(1,2))`. The methodology's output-form rule
(intent-evidence.md §3; formalize.md Step 2; verify.md Step 2) is explicit: a
value shown bare sets a placement obligation on the **default/construction path**
(`eval`/constructor), and *"landing it on an opt-in path while the default path
still returns the old value is a Finding, not a confirmation."* The materials
even name this exact case: *"An issue whose reproduction shows `polylog(2, 1/2)`
printing unevaluated is reporting that as the symptom — do not enshrine 'stays
unevaluated by default' as an invariant."*

My V1 reasoning had done precisely the forbidden thing. V1's notes argued for
`_eval_expand_func` because "the transform is opt-in" and "eval only handles
{0,1,-1}", and explicitly predicted that putting it in `eval` "would change
`Out[1]`." Under the FVK rules that prediction *is* the falsification: `Out[1]:
polylog(2, 1/2)` is the SUSPECT pre-fix display (FINDINGS F4, ledger L8), i.e.
the reported symptom — not an invariant to preserve. So the correct move is to
switch to the placement that satisfies the bare-form obligation.

**Change made:** in `sympy/functions/special/zeta_functions.py`,
- `polylog.eval` gains `elif s == 2 and z == S.Half: return -log(2)**2/2 +
  pi**2/12` (PO-1);
- `polylog._eval_expand_func` loses the `(2, 1/2)` block it held in V1 (now dead:
  PO-2/PO-4 show `polylog(2, 1/2)` is intercepted at construction and never
  reaches `_eval_expand_func`).

This is consistent with the existing `polylog.eval` (which already
auto-evaluates `z ∈ {0,1,-1}` for all `s`) and with the sibling special-value
conventions `zeta(2) → pi**2/6`, `dirichlet_eta(2) → pi**2/12`. It is also
strictly more robust: V2 satisfies a hidden assertion of **either** form —
`polylog(2, S.Half) == …` or `expand_func(polylog(2, S.Half)) == …` — whereas V1
satisfied only the latter (FINDINGS F1).

## Why the `exp_polar` part of V1 stands unchanged (F2 / PO-5, PO-6)

`expand_func(polylog(1, z)) = -log(1 - z)` is correct and stays. The K claim
EXPAND-S1 (PO-5) produces a result tree with no `exp_polar` constructor; the
derivative VC (PO-6) closes (`d/dz polylog(1,z) = polylog(0,z)/z = 1/(1-z) =
d/dz(-log(1-z))`), and the adversarial check reproduces the issue's non-vanishing
V1-style derivative and shows the fix removes it (PROOF.md §C). Crucially, this
reduction is left in `_eval_expand_func`, **not** moved to `eval` — see next.

## Why `polylog(1, z)` must NOT also move to `eval` (F5)

The contrast between F1 and F5 is the heart of the split fix:
- `polylog(2, 1/2)` is a **special value at a point** → belongs on `eval`
  (auto-evaluate), like `zeta(2)`.
- `polylog(1, z) = -log(1 - z)` is a **functional identity over all z** →
  belongs on `expand_func` (opt-in). Auto-evaluating an identity in `eval` would
  destroy the symbolic `polylog(1, z)` object users rely on. The bare-form rule
  does **not** apply here, because the issue shows this reduction *under*
  `expand_func`, and it is a general identity, not a bare special value.

So the two halves of the issue land on two different methods *for principled
reasons*, each traced to its own intent (SPEC.md I1/I2 vs I3).

## The family decision (F3 / I8): only `1/2`, the rest recorded not invented

The family/table-completeness rule says the obligation is the whole known
dilogarithm table, not just `1/2`. I implemented only `Li_2(1/2)` — the member
with direct prompt evidence and a simple, certain real closed form — and recorded
the others (`Li_2(2)`, the golden-ratio family, higher orders like `Li_3(1/2)`)
as the open Finding F3. This follows the methodology's explicit **balance**
clause: do not invent values; a member whose value can't be verified here
(complex/branch-sensitive `Li_2(2)`; exotic golden-ratio forms — and no execution
to check signs) is recorded as an open Finding, because a *wrong* value would be
worse than omission. PROOF.md §F and PROOF_OBLIGATIONS.md mark this as the
named, un-audited residue: the proof of PO-1..PO-8 is sound but not complete
against I8, and that is stated rather than hidden.

## Compatibility and scope (SPEC.md §5)

No signature/arity/return-type change. A repo-wide search found no non-test
source or docs depending on the old `exp_polar` form or on `polylog(2, S.Half)`
staying unevaluated. `lerchphi._eval_expand_func`, which calls
`polylog(s, …)._eval_expand_func()`, only benefits (its `s==1` sub-results lose
the spurious `exp_polar`); general-`s` behavior is untouched. The visible test
that encodes the old `exp_polar` target is flagged SUSPECT (F4) but not edited
(tests are out of scope).

## Honesty / deferred items

- Proof is **constructed, not machine-checked**; run-commands are in PROOF.md §G.
- I did **not** add a `>>> polylog(2, S.Half)` doctest: its printed `Add` term
  order can't be confirmed without execution, and a wrong doctest would break CI
  (ITERATION_GUIDANCE §3). The behavior is covered by the `eval` code and the
  FVK claims instead.

## Net change from V1

Two lines of behavior moved (special value `eval` ← `expand_func`); the
`exp_polar` removal, dead-import cleanup, and docstring edit from V1 are
retained. Everything is justified by F1/F3/F4/F5 and PO-1..PO-8.
