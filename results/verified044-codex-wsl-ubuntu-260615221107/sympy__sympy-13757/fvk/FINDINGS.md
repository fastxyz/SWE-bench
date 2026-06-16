# FVK Findings

Status: constructed, not machine-checked.

## F-1: Pre-V1 right-hand `Poly` dispatch bug is addressed by V1

Classification: code bug in baseline before V1; resolved by V1.

Evidence: E1-E6; proof obligations PO-1, PO-2, PO-3.

Concrete examples:

- Input: `x*Poly(x)`.
- Pre-V1 observed behavior from the issue: `x*Poly(x, x, domain='ZZ')`.
- Expected behavior: `Poly(x**2, x, domain='ZZ')`.
- V1 mechanism: `Poly._op_priority == 10.001` is strictly greater than ordinary `Expr._op_priority == 10.0`, so `Expr.__mul__` delegates to `Poly.__rmul__`, which converts `x` to `Poly(x, x)` and multiplies.

- Input: `S(-2)*Poly(x)`.
- Pre-V1 observed behavior from the issue: `-2*Poly(x, x, domain='ZZ')`.
- Expected behavior: `Poly(-2*x, x, domain='ZZ')`.
- V1 mechanism: the same priority delegation reaches `Poly.__rmul__`, which converts `S(-2)` to a compatible constant polynomial and multiplies.

Recommended code action: keep V1 source unchanged.

## F-2: V1 routes more than multiplication, but no public compatibility blocker was found

Classification: compatibility consideration; no source bug found.

Evidence: E7-E8; proof obligations PO-4, PO-5.

Concrete behavior considered:

- Input class: ordinary `Expr` on the left and `Poly` on the right for binary operations using `call_highest_priority`.
- Observed candidate behavior: `Poly` can now receive reflected operations for ordinary left-hand expressions, not only multiplication.
- Expected compatibility behavior: this is acceptable when `Poly` already defines the reflected operation and preserves fallback behavior for non-convertible operands.

Reasoning: SymPy's priority mechanism is class-level, not operator-specific. A multiplication-only priority knob does not exist. The alternative would special-case `Poly` in core multiplication, duplicating the dispatch mechanism and leaving analogous reverse `Poly` arithmetic inconsistent. Public tests already assert reverse `Poly` arithmetic for scalar operands, supporting the broader dispatch direction.

Recommended code action: keep V1 source unchanged. Add focused tests in a normal development setting for `x*Poly(x)`, `S(-2)*Poly(x)`, and at least one incompatible-expression fallback. Do not edit tests in this benchmark session.

## F-3: Proof is constructed but not machine-checked

Classification: proof capability / process limitation.

Evidence: FVK honesty gate; proof obligation PO-6.

Concrete effect: no `kompile`, `kast`, `kprove`, Python, or test command has been run. The K files and proof are review artifacts and future machine-check inputs, not completed machine verification.

Recommended action: keep tests until the emitted commands in `fvk/PROOF.md` are run and return `#Top`.

## Summary

No new source defect was found during the FVK audit. V1 stands unchanged.
