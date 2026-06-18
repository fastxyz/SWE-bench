# Findings

Status: constructed, not machine-checked.

## FVK-1: Legacy direct rendering reproduces the reported bug

Input shape:

`3*Subs(-x+y, (x,), (1,))`

Legacy modeled output:

`mulTex(numTex(3), subsTex(rawAdd, assignOne))`

Expected output:

`mulTex(numTex(3), subsTex(paren(rawAdd), assignOne))`

Evidence:

- `PUBLIC_EVIDENCE_LEDGER.md` entries `E2`, `E3`, and `E4`.
- `subs-latex-spec.k` claim `LEGACY-COUNTEREXAMPLE-DIAGNOSTIC`.

Classification: code bug in the legacy `_print_Subs` expression rendering
mechanism.

Resolution in V1: `_print_Subs` now calls `parenthesize(expr,
PRECEDENCE["Mul"], strict=True)` before composing the substitution bar. The
candidate claim `ISSUE-EXAMPLE` captures the corrected shape.

## FVK-2: V1 preserves the non-additive frame condition

Input shape:

`Subs(x*y, (x, y), (1, 2))`

Expected and modeled V1 output:

`subsTex(rawMul, assignTwo)`

Evidence:

- `PUBLIC_EVIDENCE_LEDGER.md` entry `E5`.
- `subs-latex-spec.k` claims `PAREN-NONLOW-STRICT` and
  `SUBS-NONLOW-PRECEDENCE`.

Classification: no bug found; regression check passed in the modeled fragment.

Resolution decision: no source edit is justified. V1 stands unchanged.

## Proof-derived findings from verify

No counterexample, unmet proof obligation, or compatibility blocker was found in
the modeled fragment.

The proof is constructed, not machine-checked. The exact `kompile` and `kprove`
commands are listed in `PROOF.md`, but they were intentionally not executed.

## Test recommendations

Do not remove tests. Because the proof was not machine-checked, any redundancy
recommendation would be conditional only. The existing non-additive LaTeX test
also remains useful compatibility coverage until `kprove` returns `#Top`.
