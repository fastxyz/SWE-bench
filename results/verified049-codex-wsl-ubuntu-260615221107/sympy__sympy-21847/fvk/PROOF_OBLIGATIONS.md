# Proof Obligations

Status: constructed obligations, not machine-checked.

## PO-1: Integer Mode Validation

Evidence: E9 and existing source behavior.

Obligation: negative integer `max_degree` or `min_degree` raises `ValueError`; omitted `min_degrees` means `min_degree = 0`; `min_degree > max_degree` yields no monomials.

Status: discharged by inspection. V2 does not alter these guards.

## PO-2: Unit Monomial Boundary

Evidence: E3, E7, E8.

Obligation: when `variables` is empty or `max_degree == 0`, `S.One` is yielded iff `min_degree == 0`; otherwise no monomial is yielded.

Status: discharged by V2 source lines 116-119 and formal claim C5.

Finding trace: F2.

## PO-3: Candidate Upper Bound

Evidence: implementation candidate generation and docstring upper bound.

Obligation: every candidate reaching the lower-bound filter has total degree at most `max_degree`. For the commutative branch, this follows from `combinations_with_replacement(variables + [S.One], max_degree)` and counting non-`1` factors. For the non-commutative branch, this follows from `product(variables + [S.One], repeat=max_degree)` and counting non-`1` factors.

Status: discharged by implementation reasoning in the mini-model. Full `itertools` and SymPy object semantics remain an abstraction boundary in F4.

## PO-4: Commutative Lower-Bound Exactness

Evidence: E2, E3, E5.

Obligation: a commutative candidate is yielded exactly when its total exponent sum is at least `min_degree`.

Status: discharged by V2 source line 131 and K claims C1-C3. The pre-fix `max(...)` predicate fails C4.

Finding trace: F1.

## PO-5: Non-Commutative Lower-Bound Exactness

Evidence: E3, E5, public tests showing a distinct non-commutative branch exists.

Obligation: a non-commutative candidate is yielded exactly when its total count of non-`1` factors is at least `min_degree`.

Status: discharged by V2 source line 143 and K claims C1-C2. The same legacy `max(...)` predicate had the same mixed-word failure mode.

Finding trace: F1.

## PO-6: Legacy Predicate Counterexample

Evidence: E2.

Obligation: demonstrate that the old predicate cannot satisfy public intent.

Status: discharged by counts `[1, 2, 0]`, `min_degree = 3`: `max = 2`, `sum = 3`. Legacy rejects; total-degree spec accepts.

Finding trace: F1.

## PO-7: List-Valued Mode Frame

Evidence: E6.

Obligation: V2 must not alter the list-valued `max_degrees` / `min_degrees` branch.

Status: discharged by diff inspection: edits are confined to integer total-degree branch lines 116-143.

## PO-8: Public Compatibility

Evidence: E10 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Obligation: preserve public signature, generator return shape, and default callsite behavior.

Status: discharged by compatibility audit. No source callsite update required.

Finding trace: F5.
