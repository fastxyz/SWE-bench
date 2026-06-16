# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Bound discriminator

Statement: after `cothm = coth(m)` is assigned in the additive branch,
the subsequent condition must read `cothm`, not an unbound or unrelated name.

Evidence: E2 and E3 in `SPEC.md`.

Discharge: V1 source reads `if cothm is S.ComplexInfinity`. The mini-semantics
binds `CothValue(M)` into the `cothm` cell before `chooseCothBranch` inspects
that cell.

Finding trace: F1.

## PO2 - Complex-infinity branch result

Statement: if the computed discriminator satisfies
`cothm is S.ComplexInfinity`, the branch returns `coth(x)`.

Evidence: existing branch structure in `hyperbolic.py`; public hint requires
only the discriminator name correction.

Formal claim: first claim in `fvk/coth-eval-spec.k`.

Finding trace: F1.

## PO3 - Non-complex-infinity branch result

Statement: if the computed discriminator is not `S.ComplexInfinity`, the
branch returns `tanh(x)`.

Evidence: existing branch structure and code comment `else: # cothm == 0`.
No allowed public evidence requests changing this behavior.

Formal claim: second claim in `fvk/coth-eval-spec.k`.

Finding trace: F1.

## PO4 - Frame condition for unrelated behavior

Statement: the repair must not change numeric special cases, infinity handling,
imaginary-coefficient handling, inverse-function simplifications, method
signature, or public call pattern of `coth.eval`.

Evidence: the issue localizes the defect to the undefined name; public tests
show existing special-value behavior for `coth`.

Discharge: V1 changes exactly one identifier in the additive branch condition.

Finding trace: F2.

## PO5 - Public compatibility

Statement: the patch must preserve the public API shape of `coth.eval`.

Evidence: no public requirement asks for a signature or dispatch change.

Discharge: V1 does not alter parameters, return protocol, imports, inheritance,
or call-site contracts.

Finding trace: F2.
