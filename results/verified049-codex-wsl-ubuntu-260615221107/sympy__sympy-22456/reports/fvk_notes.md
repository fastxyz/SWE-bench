# FVK Notes

## Decision: keep V1 source unchanged

The FVK audit confirmed V1 against the public intent and did not justify a V2
source edit. This decision traces to:

- `fvk/FINDINGS.md` F1: the original defect was empty `String.args`; V1 fixes it
  by storing `Str(text)` in `_args`.
- `fvk/PROOF_OBLIGATIONS.md` PO1 and PO2: `String` and subclasses now have
  Basic-compatible args and reconstruct through `expr.func(*expr.args)`.
- `fvk/FINDINGS.md` F2: the raw-string-in-args alternative was rejected because
  it violates the Basic argument convention; PO1 discharges that risk.

## Decision: preserve public String API behavior

I kept `.text` as a Python string and retained kwargs reconstruction rather than
making `String.text` itself a `Str`. This traces to:

- `fvk/PROOF_OBLIGATIONS.md` PO3: kwargs reconstruction is an explicit frame
  condition.
- `fvk/PROOF_OBLIGATIONS.md` PO4: invalid non-string text remains rejected.
- `fvk/FINDINGS.md` F1 and F2: only the internal reconstruction carrier needed
  to change; the public slot did not.

## Decision: keep the `Token.atoms()` frame from V1

The audit confirmed that V1's `Token.atoms()` override is justified and should
remain. This traces to:

- `fvk/FINDINGS.md` F3: making `String.args` nonempty would otherwise expose the
  internal `Str` wrapper during default codegen atom traversal.
- `fvk/PROOF_OBLIGATIONS.md` PO5: default `atoms()` over codegen token trees
  must keep returning codegen `String` leaves.

## Decision: no tests or commands run

The task forbids execution. I therefore produced constructed proof artifacts
and commands without running them. This traces to:

- `fvk/FINDINGS.md` F4: proof status is constructed, not machine-checked.
- `fvk/PROOF_OBLIGATIONS.md` PO7: exact future `kompile`, `kast`, and `kprove`
  commands are included in `fvk/PROOF.md`.

## Artifacts produced

Required artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK methodology artifacts:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-sympy-string.k`
- `fvk/sympy-string-spec.k`
