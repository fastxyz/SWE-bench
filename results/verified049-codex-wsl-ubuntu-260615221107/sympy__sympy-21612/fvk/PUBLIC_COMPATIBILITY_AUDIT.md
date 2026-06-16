# Public Compatibility Audit

Status: source-inspection audit; no execution performed.

Changed public symbols: none.

Changed signatures: none.

Changed dispatch shape: none.

Changed public return types: none.

Changed producer/consumer format: the only observable change is the string content emitted by `StrPrinter._print_Mul` for a denominator reciprocal whose base is a `Pow`. This is the public-intent repair. Existing simple quotient and `Mul`-base grouping behavior is preserved by the unchanged branches and by keeping `Mul` in the guard.

Public callsites and overrides: no new method call, keyword, helper, or override contract was introduced. The fix changes only an `isinstance` tuple inside the existing `_print_Mul` implementation.

Compatibility result: pass.
