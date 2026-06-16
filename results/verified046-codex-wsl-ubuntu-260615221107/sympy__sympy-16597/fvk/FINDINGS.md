# FVK Findings

Status: constructed, not machine-checked.

## F-1: Resolved old-assumptions closure gap

Classification: code bug in V0; resolved by V1.

Input: `Symbol('m', even=True).is_finite`.

Pre-V1 observed behavior: `None`, as reported in `benchmark/PROBLEM.md`.

Expected behavior: `True`, because an even value is an integer number and must
be finite.

Cause: the old rule graph contained `even == integer & !odd`,
`integer -> rational`, and `rational -> real`, but no path from `rational` to
`finite`.

Resolution: V1 adds `rational -> finite` in `_assume_rules`.

Related proof obligations: PO-1, PO-2.

## F-2: Resolved integer variant

Classification: code bug in V0; resolved by V1.

Input: `Symbol('i', integer=True).is_finite`.

Pre-V1 observed behavior: `None`, as reported in `benchmark/PROBLEM.md`.

Expected behavior: `True`, because integer values are rational numbers and
rational numbers are finite.

Resolution: the same V1 `rational -> finite` rule discharges this variant
through the existing `integer -> rational` implication.

Related proof obligations: PO-1, PO-3.

## F-3: Rational-level placement confirmed

Classification: confirmation of V1 design.

Input: `Symbol('r', rational=True).is_finite`.

Pre-V1 behavior by graph analysis: no rule path reached `finite`.

Expected behavior: `True`, based on the public hint and the mathematical meaning
of rational numbers.

Resolution: V1 places the rule at `rational`, not at each integer/parity leaf.
This covers `integer`, `even`, and `odd` through existing closure without
duplicating edges.

Related proof obligations: PO-1, PO-4.

## F-4: Broad `real -> finite` change rejected for this pass

Classification: compatibility-sensitive alternative rejected.

Input: `Symbol('x', real=True).is_finite`.

Observed/source behavior under V1: unchanged by this patch.

Alternative considered: add `real -> finite`.

Reason rejected: the public hint explicitly says old-assumption `real` currently
behaves broadly and adding `finite` to it would probably break code. Public
tests in the newer `ask` path also still reason about signed unbounded
quantities. The issue's examples require rational-derived number classes, not a
global real narrowing.

Related proof obligations: PO-5.

## F-5: Newer `ask(Q.*)` fact tables are a separate cleanup

Classification: residual compatibility note, not a blocker for V1.

Input class: `ask(Q.finite(x), Q.integer(x))` or
`ask(Q.finite(x), Q.rational(x))` for a generic `x`.

Current source observation: the newer assumptions API has its own
`get_known_facts` and generated `ask_generated.py` tables. Those tables are not
the mechanism used by `Symbol(...).is_finite`, and changing them requires
regenerating generated artifacts, which is explicitly a separate workflow.

Decision: keep V1 scoped to old `.is_*` assumptions. If the newer assumptions
API is later brought into alignment, update `get_known_facts`, regenerate
`ask_generated.py`, and audit the finite/sign public tests as a separate patch.

Related proof obligations: PO-7.
