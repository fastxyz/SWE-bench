# Proof Obligations

Status: all source-level obligations discharged by V1; formal proof
constructed but not machine-checked.

## PO1 - Concrete Reproducer

For `symbols(('q:2', 'u:2'), cls=Function)`, `q[0]` must be constructed through
`Function('q0')`, producing an undefined function class.

Evidence: E1, E2, E6.

Discharge: The outer iterable branch recurses into `'q:2'` with `cls=Function`;
the existing range branch constructs each expanded name with `cls(s, **args)`.

Status: discharged by `repo/sympy/core/symbol.py`.

## PO2 - Bug Localization

The pre-fix mechanism must explain the observed `Symbol` result.

Evidence: E1, E7.

Discharge: Before V1, the iterable branch called `symbols(name, **args)`.
Because `cls` is keyword-only and absent from `args`, recursive calls used the
default `Symbol`. That exactly explains `q[0]` becoming a `Symbol`.

Status: discharged by audit.

## PO3 - Recursive Class Preservation

For every non-string iterable handled by `symbols()`, each recursive call must
receive the active `cls`.

Evidence: E1, E4, E7.

Discharge: V1 changes the only recursive self-call to
`symbols(name, cls=cls, **args)`.

Status: discharged by source inspection and claim
`SYMBOLS-ITERABLE-PRESERVES-CLASS`.

## PO4 - Output Shape Preservation

The repair must preserve iterable output shape and container reconstruction.

Evidence: E3, E5.

Discharge: V1 does not change `result.append(...)` or
`return type(names)(result)`. It changes only the keyword arguments passed to
the recursive call.

Status: discharged by source inspection and claim
`SYMBOLS-FUNCTION-NESTED-RANGES`.

## PO5 - String and Range Behavior Unchanged

Existing string parsing and range expansion should keep using the active `cls`
and should not be refactored.

Evidence: E4, E5.

Discharge: V1 does not alter the string branch. The existing range branch still
uses `cls(s, **args)` for each expanded name.

Status: discharged by source inspection.

## PO6 - Keyword Argument Preservation

Assumptions and other keyword arguments must continue to propagate through
recursive calls.

Evidence: I5 and existing API behavior.

Discharge: V1 preserves `**args` in the recursive call and adds only
`cls=cls`.

Status: discharged by source inspection.

## PO7 - Public Compatibility

The public signature, callsites, override behavior, and return shape must remain
compatible.

Evidence: E4, E5 and `PUBLIC_COMPATIBILITY_AUDIT.md`.

Discharge: The signature is unchanged, no virtual dispatch shape changed, and
container reconstruction remains identical.

Status: discharged.

## PO8 - Honesty Gate

Do not claim machine verification or remove tests without running K tooling.

Evidence: FVK verify instructions and benchmark no-execution rule.

Discharge: The proof artifacts include commands but mark the proof
constructed, not machine-checked. No tests were run or modified.

Status: discharged.
