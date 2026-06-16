# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - `Basic.__eq__` unsympifiable fallback

- Claim: `basicEq(BasicUnsympifiable) => RNotImplemented`.
- Code path: `repo/sympy/core/basic.py`, `except SympifyError`.
- Required by: F1, E1, E2.
- Status: discharged by source inspection and K claim `BASIC-UNSYMPIFIABLE-EQ`.

## PO2 - `Basic.__eq__` different-type fallback

- Claim: `basicEq(BasicDifferentType) => RNotImplemented`.
- Code path: `repo/sympy/core/basic.py`, `if type(self) != type(other)`.
- Required by: F2, E3.
- Status: discharged by source inspection and K claim `BASIC-DIFFERENT-TYPE-EQ`.

## PO3 - `__ne__` preserves `NotImplemented`

- Claim: `basicNe(BasicUnsympifiable) => RNotImplemented`; numeric `numberNe(NumUnknown) => RNotImplemented`; singleton `singletonNe(SingletonUnsupported) => RNotImplemented`.
- Code path: `Basic.__ne__` and numeric `__ne__` methods.
- Required by: F3.
- Status: discharged by source inspection and K claims.

## PO4 - Python equality dispatch is restored

- Claim: `pyEq(RNotImplemented, RTrue) => RTrue` and `pyEq(RNotImplemented, RNotImplemented) => RFalse`.
- Code path: not SymPy code; this models the Python rich-comparison dispatch rule the issue cites.
- Required by: F1, F2.
- Status: discharged in the abstract semantics. Full Python dispatch is trusted as public language behavior.

## PO5 - `Expr` ordering unsupported operands delegate

- Claim: `exprOrder(Lt, OrderUnsympifiable) => RNotImplemented` and `exprOrder(Ge, OrderUnsympifiable) => RNotImplemented`.
- Code path: `repo/sympy/core/expr.py`, `except SympifyError` branches in ordering methods.
- Required by: F5.
- Status: discharged by source inspection and representative K claims; `Le` and `Gt` are syntactically identical cases.

## PO6 - Numeric overrides do not bypass fallback

- Claim: `numberEq(NumUnknown) => RNotImplemented`, `numberEq(NumNonNumberBasic) => RNotImplemented`, and `numberNe(NumUnknown) => RNotImplemented`.
- Code path: `Float`, `Rational`, `Integer`, `NumberSymbol`, and abstract `Number` ordering overrides.
- Required by: F6.
- Status: discharged by source inspection and K claims.

## PO7 - Singleton equality preserves known behavior while delegating unsupported operands

- Claims: `singletonEq(SingletonSame) => RTrue`, `singletonEq(SingletonOtherNumber) => RFalse`, `singletonEq(SingletonUnsupported) => RNotImplemented`.
- Code path: `Infinity.__eq__`, `NegativeInfinity.__eq__`, `NaN.__eq__`.
- Required by: F4 and F6.
- Status: V1 failed this obligation by sympifying singleton equality inputs; V2 discharges it.

## PO8 - Frame: known invalid or numeric behavior remains definite

- Claims: `exprOrder(Lt, OrderInvalidComplexOrNaN) => RTypeError`; `numberEq(NumKnown) => RBool`.
- Code path: `Expr` invalid complex/NaN checks and supported numeric comparison branches.
- Required by: F4, F5, F6.
- Status: discharged by source inspection and K claims.

## PO9 - Public compatibility

- Claim: signatures and call shapes are unchanged; no test files are edited.
- Code path: all changed methods retain `(self, other)` and only branch return categories change.
- Required by: F7 and compatibility audit.
- Status: discharged by static source inspection.
