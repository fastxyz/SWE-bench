# FVK Notes

## Source Changes After V1

`repo/sympy/printing/latex.py`

The FVK audit kept V1's `_latex_power_base` design and made one small
consistency edit in the folded fractional-power branch: the function-specific
fallback is now guarded by `custom_base is None`.

Trace:

- `fvk/FINDINGS.md` F2 identifies the proof-derived consistency gap: every
  branch that appends an outer exponent should let a custom grouped power base
  win.
- `fvk/PROOF_OBLIGATIONS.md` PO2 requires folded fractional creator powers to
  produce `{L}^{P/Q}`.
- `fvk/PROOF_OBLIGATIONS.md` PO5 requires non-creator and ordinary function
  behavior to stay on legacy paths when no hook exists.

This edit has no expected user-visible effect for current `Creator` subclasses,
because they are not functions, but it makes the branch match the stated proof
obligation for the optional hook.

## V1 Decisions Confirmed

`repo/sympy/physics/secondquant.py`

The audit confirms keeping `_latex_power_base` on the shared `Creator` base
class.

Trace:

- `fvk/FINDINGS.md` F1 records the resolved standard-power bug.
- `fvk/PROOF_OBLIGATIONS.md` PO1 requires standard creator powers to produce
  `{L}^{E}`.
- `fvk/PROOF_OBLIGATIONS.md` PO3 excludes the ungrouped
  `^\dagger_{...}^{...}` double-superscript pattern.

`repo/sympy/physics/secondquant.py`

The audit confirms leaving `CreateBoson._latex` and `CreateFermion._latex`
unchanged.

Trace:

- `fvk/FINDINGS.md` F3 confirms direct creator LaTeX is a frame condition.
- `fvk/PROOF_OBLIGATIONS.md` PO4 requires direct `Bd` and `Fd` output to remain
  unwrapped.

`repo/sympy/printing/latex.py`

The audit confirms keeping the optional hook narrow rather than broadening
`parenthesize_super` for every non-symbol base.

Trace:

- `fvk/FINDINGS.md` F4 confirms non-creator power printing remains on legacy
  paths.
- `fvk/PROOF_OBLIGATIONS.md` PO5 requires existing symbol, function, derivative,
  and other non-creator behavior to be preserved.

## Decisions Not to Change

I did not change state-label rendering in `CreateBoson._latex` or
`CreateFermion._latex`.

Trace:

- `fvk/FINDINGS.md` F5 records this as existing behavior outside the public
  evidence for the reported double-superscript bug.
- `fvk/PROOF_OBLIGATIONS.md` PO6 requires public compatibility and argues
  against unrelated output-format changes.

I did not modify tests.

Trace:

- The benchmark forbids test edits.
- `fvk/PROOF.md` labels the proof constructed, not machine-checked, so test
  removal would not be justified even outside the benchmark.

## Verification Status

No tests, Python, or K tooling were run. The FVK proof is a constructed proof
over the audited printer branches, with exact commands written in
`fvk/PROOF.md` for later machine checking.

