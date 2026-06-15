# Formal Spec In English

Status: constructed, not machine-checked.

## Claims

1. `ARGS-DROP-NONE`: For every positional value list, `normalizeArgs()` returns the same list with exactly the `None` entries removed and all other entries kept in their original order.
2. `KWARGS-DROP-NONE`: For every keyword map, `normalizeKwargs()` returns the same map with exactly the entries whose value is `None` removed and all other entries kept under the same key.
3. `OPTIONAL-KWARGS`: For a representative optional URL candidate with `arg1=1` and `arg2=None`, keyword normalization produces a map containing `arg1=1` and no `arg2`, which is the shape required for the shorter optional URL candidate.
4. `OPTIONAL-ARGS`: For a representative optional URL candidate with positional values `[1, None]`, positional normalization produces `[1]`, which is the shape required for the shorter optional URL candidate.
5. `EMPTY-STRING-PRESERVED`: For a representative value list containing the empty string, normalization keeps the empty string because it is not `None`.

## Frame Conditions

1. The `ValueError` for mixing positional and keyword arguments is checked before normalization and therefore remains unchanged.
2. Public function signatures are unchanged.
3. Regex matching, quoting, converter execution for non-`None` values, resolver population, and URL-conf lookup are not modified by V1.

