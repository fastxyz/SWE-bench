# FVK Spec

Status: constructed, not machine-checked.

## Scope

This FVK run audits the comparison methods touched by V1:

- `Basic.__eq__` and `Basic.__ne__` in `repo/sympy/core/basic.py`
- `Expr.__lt__`, `Expr.__le__`, `Expr.__gt__`, and `Expr.__ge__` in `repo/sympy/core/expr.py`
- core numeric comparison overrides in `repo/sympy/core/numbers.py`

The observable property is the rich-comparison result category:

- definite boolean result
- `NotImplemented`
- invalid comparison error

The model intentionally abstracts away expression tree contents, arithmetic value computation, and Python object allocation. Those are not the changed property. It preserves the property axis required by the issue: whether a comparison method stops dispatch with a definite result or returns `NotImplemented` to allow reflected dispatch.

## Public Intent Ledger

See `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The critical obligations are:

- E1-E3: `Basic.__eq__` returns `NotImplemented` for unsympifiable operands and for sympified different SymPy types.
- E4: ordering methods follow the same unsupported-operand fallback.
- E5: equality dispatch with two `NotImplemented` results produces final `False`.
- E6: supported numeric interop remains definite.
- E7-E8: V1 singleton sympification was implementation-derived drift and must be removed.

## Formal Claims

The K files are:

- `fvk/mini-python-richcompare.k`: a minimal abstract semantics for rich-comparison result categories and Python-style equality dispatch.
- `fvk/sympy-richcompare-spec.k`: reachability claims for the comparison obligations.

Claim families:

- `BASIC-UNSYMPIFIABLE-EQ`: `basicEq(BasicUnsympifiable) => RNotImplemented`
- `BASIC-DIFFERENT-TYPE-EQ`: `basicEq(BasicDifferentType) => RNotImplemented`
- `BASIC-NE-PRESERVES-NI`: `basicNe(BasicUnsympifiable) => RNotImplemented`
- `PY-EQ-DELEGATES`: `pyEq(RNotImplemented, RTrue) => RTrue`
- `PY-EQ-BOTH-NI-FALSE`: `pyEq(RNotImplemented, RNotImplemented) => RFalse`
- `EXPR-ORDER-UNSUPPORTED`: `exprOrder(Lt, OrderUnsympifiable) => RNotImplemented`
- `EXPR-ORDER-INVALID`: `exprOrder(Lt, OrderInvalidComplexOrNaN) => RTypeError`
- `NUMBER-EQ-UNKNOWN`: `numberEq(NumUnknown) => RNotImplemented`
- `NUMBER-NE-PRESERVES-NI`: `numberNe(NumUnknown) => RNotImplemented`
- `SINGLETON-SAME`: `singletonEq(SingletonSame) => RTrue`
- `SINGLETON-OTHER-NUMBER`: `singletonEq(SingletonOtherNumber) => RFalse`
- `SINGLETON-UNSUPPORTED`: `singletonEq(SingletonUnsupported) => RNotImplemented`

## Preconditions

The proof is partial correctness over the comparison-method bodies:

- The method is entered with a classified comparison case from the semantics.
- For ordering invalidity, the other operand has already sympified and is known to be complex/NaN invalid.
- For unsupported fallback, the operand is outside the method's supported comparison domain.

There are no loops and no termination measure obligations in this patch.

## Frame Conditions

- Method signatures are unchanged.
- Known numeric comparison logic is preserved: supported `Float`, `Rational`, `Integer`, `NumberSymbol`, and singleton-vs-number cases still return definite booleans.
- Existing TypeError behavior for recognized invalid complex/NaN ordering is preserved.
- V2 removes V1-only singleton equality sympification, so equality with sympifiable non-identical non-SymPy values is not newly widened.
