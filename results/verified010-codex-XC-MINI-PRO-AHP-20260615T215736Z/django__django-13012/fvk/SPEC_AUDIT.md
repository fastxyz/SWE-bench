# Spec Audit

| Formal English claim | Intent entry | Result | Notes |
|---|---|---|---|
| Wrapped `Value` returns no group-by columns. | Intent 1, 2 | Pass | Directly matches the reported issue and `Value` behavior. |
| Wrapper delegates to alias-aware child expressions. | Intent 1, 3 | Pass | Required by "arbitrary Query expression" and alias-sensitive in-tree expressions. |
| Wrapper preserves legacy missing-alias deprecation behavior. | Intent 3, 4 | Pass | Derived from public deprecation source and tests. |
| Wrapper signature and unrelated expression behavior are unchanged. | Intent 5 | Pass | V2 keeps the public method signature and changes only the wrapper method. |

No claim is candidate-derived without public evidence. No required behavior is
marked ambiguous.
