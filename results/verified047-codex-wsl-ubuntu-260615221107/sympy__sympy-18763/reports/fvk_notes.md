# FVK Notes

## Decision summary

V1 stands unchanged. No additional source files were edited in the FVK phase.

The deciding entries are:

- `fvk/FINDINGS.md` F-001: the original issue is a real code bug in
  `_print_Subs` because an additive body was emitted ungrouped inside a
  multiplicative factor.
- `fvk/PROOF_OBLIGATIONS.md` PO-001: low-precedence substituted bodies must be
  grouped inside the substitution bar.
- `fvk/PROOF_OBLIGATIONS.md` PO-002: multiplication-precedence bodies, including
  the existing public `Subs(x*y, ...)` case, must remain unwrapped.
- `fvk/FINDINGS.md` F-003: no residual source defect was found within the
  public intent after checking V1 against PO-001 through PO-004.

## Why V1 is kept

V1 uses:

```python
latex_expr = self.parenthesize(expr, PRECEDENCE["Mul"], strict=True)
```

This discharges PO-001 because `parenthesize` wraps expressions whose
traditional precedence is lower than multiplication. It also discharges PO-002
because `strict=True` does not wrap expressions whose precedence is exactly
multiplication, preserving the public `Subs(x*y, ...)` output recorded in
F-002.

The issue's expected string places parentheses around the expression inside the
substitution bar, not around the whole `Subs` factor. PO-003 captures that
composition requirement, and V1 satisfies it by fixing the factor string at
`_print_Subs` before `_print_Mul` prefixes the coefficient.

## Rejected alternatives

Changing the precedence table for `Subs` was rejected because it would either
not affect the issue output or would encourage outer parentheses around the
whole substitution factor. That conflicts with PO-003.

An `Add`-only check in `_print_Subs` was also rejected. It would satisfy the
single example, but PO-001 is naturally a precedence obligation and the printer
already has a helper for that rule. The chosen implementation also preserves
PO-002 through `strict=True`.

## FVK artifacts

I added the five requested artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the FVK formal and adequacy core required by the kit:

- `fvk/mini-python-printing.k`
- `fvk/latex-subs-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

The proof is constructed, not machine-checked. No tests, Python, K tooling, or
other code execution were run.
