# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

The audited unit is the `Permutation.__new__` constructor path in `repo/sympy/combinatorics/permutations.py` that distinguishes array-form input from list-of-lists cyclic input.

The FVK model intentionally covers only the observable behavior involved in the issue:

- array-form duplicate validation;
- cyclic list input, including non-disjoint cycles;
- left-to-right cycle folding;
- the reported double-transposition input;
- preservation of size extension and constructor API shape as frame conditions.

It does not model the full SymPy object hierarchy, printing, hashing, or unrelated permutation operations.

## Public Intent Ledger

| ID | Evidence | Obligation |
| --- | --- | --- |
| S1 | Issue: `Permutation([[0,1],[0,1]])` should construct identity, not raise. | The concrete double-transposition input is in domain and returns identity. |
| S2 | Issue: non-disjoint cycles "should be applied in left-to-right order". | Cross-cycle repeated elements are allowed and ordered by list position. |
| S3 | Issue: no reason non-disjoint cycles should be forbidden. | No global disjointness precondition is allowed for cyclic list input. |
| S4 | Public docs: list-of-lists is cyclic form; products of cycles are order-sensitive. | Constructor list-of-lists input must compose cycles, not treat repeated elements as array duplicates. |
| S5 | Public tests/docs: array-form duplicate input is invalid. | Array duplicate rejection remains unchanged. |
| S6 | `Cycle` implementation and tests reject duplicates inside one cycle and negative elements. | Per-cycle validity remains a precondition. |
| S7 | Public docs/tests for singletons and `size`. | Singleton and size-extension behavior are preserved. |
| S8 | Public API shape. | No constructor signature or return-shape change. |

The legacy public test `Permutation([[1], [1, 2]])` raising is marked SUSPECT because it encodes the cross-cycle duplicate rejection that the issue identifies as the bug.

## Contract

For array-form input `A`:

- If `A` has duplicate entries, construction raises the repeated-elements `ValueError`.
- If `A` is otherwise valid, construction keeps the existing array-form behavior and optional size extension.

For cyclic list input `CS`:

- Domain: each individual cycle is valid according to `Cycle(*ci)`: integer entries, no negative entries, and no duplicate element within that single cycle.
- No precondition requires different cycles in `CS` to be disjoint.
- Result: starting from the identity `Cycle()`, process cycles in list order with the existing operation `c = c(*ci)`. Convert the final cycle map to array form with `c.list()`, then apply the existing size-extension behavior.
- Concrete obligation: `[[0, 1], [0, 1]]` folds as swap-then-swap and returns `[0, 1]`.

## Formal Artifacts

- `fvk/mini-permutation.k`: minimal K semantics for the constructor branches under audit.
- `fvk/permutation-constructor-spec.k`: K claims for non-disjoint cyclic input, the concrete reported identity case, array duplicate rejection, and the fold command.
- `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: adequacy and public-compatibility gate.

## V2 Source Decision

V1 already removed the semantic bug by no longer rejecting duplicates across cyclic-list input. V2 keeps that behavior and makes the proof-relevant guard explicit:

```python
if not is_cycle and has_dups(temp):
    raise ValueError('there were repeated elements.')
```

V2 also adds a doc example for `Permutation([[0, 1], [0, 1]])`.
