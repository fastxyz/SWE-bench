# FVK Specification

Status: constructed from public issue text, source inspection, and FVK methodology. No tests, Python, or K tooling were run.

## Scope

Target unit: `polylog` and the adjacent `lerchphi` expansion contributor in `repo/sympy/functions/special/zeta_functions.py`.

The formal core is a small term-rewrite abstraction:

- `fvk/mini-sympy-polylog.k`
- `fvk/polylog-spec.k`

It models only the observable expression-rewrite behavior needed for the issue: `polylog.eval`, `polylog._eval_expand_func`, and the `lerchphi` rational-argument polylog contributor. It does not model full Python or full SymPy canonicalization.

## Intent Spec

I-001: `polylog(2, Rational(1, 2))` is a concrete special value and should evaluate to `pi**2/12 - log(2)**2/2` on the default construction path.

I-002: `expand_func(polylog(2, Rational(1, 2)))` should expose the same closed form. Because the value is concrete, this is satisfied by I-001 before expansion.

I-003: `expand_func(polylog(1, z))` should be `-log(1 - z)` without `exp_polar(-I*pi)`.

I-004: Existing automatic values for `z in {0, 1, -1}` must continue to hold.

I-005: Existing opt-in symbolic expansions for order `0` and negative integer orders must continue to use `expand_func`; the issue does not require moving those symbolic identities to construction.

I-006: Callers that use polylog expansion as a subroutine must receive a valid expression even when `polylog(...)` now evaluates before expansion.

## Public Evidence Ledger

E-001, prompt: "`polylog(2, Rational(1,2))` ... Out: `polylog(2, 1/2)` ... The answer should be `-log(2)**2/2 + pi**2/12`." Obligation: construction-path special value for `polylog(2, 1/2)`. Status: encoded by PO-001.

E-002, prompt: "`polylog(2, Rational(1,2)).expand(func=True)` ... Out: `polylog(2, 1/2)` ... The answer should be ..." Obligation: expansion path must not hide the concrete value. Status: discharged by construction-path evaluation and PO-001.

E-003, prompt: "`polylog(1, z)` and `-log(1-z)` are exactly the same function for all purposes." Obligation: order-one function expansion uses `-log(1 - z)`. Status: encoded by PO-002.

E-004, prompt: "I don't see a reason for `exp_polar` here" and "`-log(1 + 3*exp_polar(-I*pi))` is just not meaningful." Obligation: do not preserve the old polar factor. Status: encoded by PO-002.

E-005, source docs: the class docstring says `z in {0, 1, -1}` is automatically expressed, while order `1`, `0`, and negative integer order identities are expressed using `expand_func`. Obligation: keep this placement distinction unless the issue supplies a concrete construction-path value. Status: encoded by PO-004.

E-006, public tests/comments: existing tests/comments still expect or describe the old polarized or unevaluated behavior. Obligation: mark SUSPECT because these conflict with the bug report. Status: finding F-004; tests were not edited.

E-007, implementation: `lerchphi._eval_expand_func` called `polylog(...)._eval_expand_func(...)` directly. Obligation: after `polylog(2, 1/2)` can evaluate to an `Add`, this contributor must use a public expression-level expansion helper. Status: encoded by PO-003.

## Formal Claims

C-001, `POLYLOG-SPEC` claim 1: `polylog(Two, Half)` reaches `pi**2/12 - log(2)**2/2`.

C-002, `POLYLOG-SPEC` claim 2: `expand_func(polylog(One, z))` reaches `-log(1 - z)`.

C-003, `POLYLOG-SPEC` claim 3: `lerch_polylog_term(Two, Half)` reaches the same closed form through `expand_func(polylog(...))`, not through a private method on the evaluated expression.

## Adequacy Audit

C-001 passes I-001 and I-002: the formal claim is neither weaker nor stronger than the issue's concrete value. It places the value on the construction path, as required by the FVK output-form rule.

C-002 passes I-003 and I-004: it removes only the polar factor in the order-one expansion and preserves the logarithmic identity requested by the issue.

C-003 passes I-006: it covers the proof-observed compatibility obligation created by the construction-path value.

No public API signature, return shape, class hierarchy, or external dispatch contract is changed.
