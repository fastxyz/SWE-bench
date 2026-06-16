# FVK Notes

Status: V1 confirmed; no additional source files changed during the FVK pass.

## Decisions

1. Kept `repo/sympy/printing/str.py` unchanged from V1. `fvk/FINDINGS.md` F1 and F2 identify the remaining intent as the nested reciprocal denominator grouping bug, and `fvk/PROOF_OBLIGATIONS.md` PO3 shows V1 discharges it by including `Pow` in the existing denominator-parenthesizing guard.

2. Did not edit the LaTeX parser. `fvk/FINDINGS.md` F3 and `fvk/PROOF_OBLIGATIONS.md` PO1 show the parser already constructs fractions as an unevaluated reciprocal denominator, which is the correct expression-tree shape. The issue is the string printer's rendering of that tree.

3. Did not broaden the repair to other printers. `fvk/FINDINGS.md` F4 and F5, plus `fvk/PROOF_OBLIGATIONS.md` PO4-PO6, frame the required compatibility behavior for `StrPrinter._print_Mul`: preserve existing `Mul`-base grouping and simple quotient output while adding the missing `Pow`-base grouping. The public issue does not require changing code printers or LaTeX output.

4. Did not modify tests or run any commands. `fvk/FINDINGS.md` F6 and `fvk/PROOF_OBLIGATIONS.md` PO7 record the honesty gate: this task forbids tests, Python, and K tooling, so proof status remains constructed, not machine-checked.

## Artifacts Written

The FVK package is under `fvk/`. The five requested artifacts are `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`. The package also includes the FVK adequacy files and a small K core: `INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, `PUBLIC_COMPATIBILITY_AUDIT.md`, `mini-str-printer.k`, and `str-printer-spec.k`.
