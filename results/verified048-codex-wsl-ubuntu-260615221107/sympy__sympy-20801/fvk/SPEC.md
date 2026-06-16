# FVK Specification for sympy__sympy-20801

Status: constructed from public intent and source inspection only. No tests, Python code, or K tooling were run.

## Scope

The audited unit is `Float.__eq__` in `repo/sympy/core/numbers.py`, specifically equality between a SymPy `Float` and Boolean-like operands. The source change under audit is the V1 early `isinstance(other, Boolean)` guard before `_sympify(other)`.

No loops or recursive functions are involved. The FVK proof is a straight-line branch proof over a minimal method-dispatch model.

## Intent Spec

1. SymPy numeric zero must not compare equal to SymPy Boolean false.
2. Equality between `S(0.0)` and `S.false` must be symmetric with `S.false == S(0.0)`.
3. Float behavior for non-Boolean numeric operands should remain unchanged.
4. Existing public behavior distinguishing native Python booleans from SymPy Boolean atoms should not be broadened without explicit intent evidence.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt issue title | "`S(0.0) == S.false returns True`" | The `True` result is the reported defect, not a behavior to preserve. | Encoded in PO1 |
| E2 | prompt examples | "`S(0.0) == S.false` -> `True`; `S.false == S(0.0)` -> `False`" | Equality must not depend on operand order for this Boolean/numeric distinction. | Encoded in PO1 and PO4 |
| E3 | prompt examples | "`S(0) == S.false` -> `False`; `S.false == S(0)` -> `False`" | Integer zero is the analogy: SymPy false is not numeric zero. | Encoded in PO1 |
| E4 | public test text | `assert S(0) != S.false`; `assert S.One != S.true` | SymPy numeric values and SymPy Boolean atoms are intentionally distinct under `==`. | Encoded in PO1 |
| E5 | public test text | `assert S(0) == False`; `assert S.One == True` | Native Python boolean compatibility exists for integer equality and should not be removed as part of this targeted issue. | Encoded as frame PO2 |
| E6 | public test text | `assert false == False`; `assert true == True` | SymPy Boolean atoms may compare equal to native booleans from the Boolean side; this does not imply equality to numbers. | Compatibility note |
| E7 | implementation | Pre-V1 `Float.__eq__` sympified `S.false` and then executed `if not self: return not other`. | The zero-Float branch treated falsey `S.false` as numeric zero before the Boolean guard. | Bug localization |

The issue's final sentence says "return True as well", but this conflicts with E1, E2, and E3. FVK treats that phrase as a typo and records the intended result as `False`.

## Formal Contract

For every SymPy `Float` value `F` and every operand `B` that is already an instance of `sympy.logic.boolalg.Boolean`:

```text
Float.__eq__(F, B) returns False.
```

For the reported point:

```text
Float.__eq__(Float(0.0), S.false) returns False.
```

Frame conditions:

```text
Float.__eq__(Float(0.0), False) follows the pre-existing native-bool path.
Float.__eq__(F, non-Boolean numeric operands) follows the pre-existing numeric paths.
Float.__eq__(F, unsympifiable operands) still returns NotImplemented.
```

## Formal Core

The minimal K model is in `fvk/mini-sympy-eq.k`. The K claims are in `fvk/float-eq-spec.k`.

The model abstracts full SymPy objects into categories needed to distinguish the defect:

- zero vs nonzero Float self values;
- already-SymPy Boolean operands such as `S.false`;
- native Python booleans before sympification;
- numeric zero/nonzero frame operands;
- unsympifiable frame operands.

This abstraction is property-complete for the audited defect because it keeps the discriminating axis: already-SymPy Boolean `S.false` and native Python `False` remain distinct before `_sympify`.

