# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entries | Verdict | Notes |
|---|---|---|---|
| C1: construction gives `.text == s` and `.args == (Str(s),)` | I1, I2, I3, E1-E6 | PASS | `Str` is public SymPy infrastructure for textual data in args; raw `str` was rejected because it violates E3. |
| C2: `expr.func(*expr.args) == expr` | I1, I2, E1, E2, E6 | PASS | This is the issue's central obligation. |
| C3: kwargs reconstruction remains true | I3, E5 | PASS | V1 leaves `Token.kwargs()` and `.text` as plain string behavior. |
| C4: invalid public text remains invalid | I4, current constructor contract | PASS | Accepting `Str` is limited to the internal reconstruction carrier. |
| C5: default atom traversal preserves codegen String leaves | I3, I5, E7 | PASS | Scoped to `Token.atoms()` to avoid changing global `Basic.atoms()` behavior. |
| C6: compatibility for callsites/subclasses | I3, E5, E7 | PASS | Constructor signature is unchanged; subclasses inherit the same reconstruction path. |

No claim is legacy-derived without public support. The only implementation facts
used as proof evidence are mechanism facts: `Token.__new__` slot construction,
`Token.__eq__`, and Basic's `_args` storage convention.
