# Formal Spec English

Status: paraphrase of the K claims and proof obligations; constructed, not machine-checked.

1. Scalar `x` claim: for any merge attrs list produced while evaluating `xr.where(..., x, ..., keep_attrs=True)`, if `x` contributes no attrs source, the attrs selector returns an empty attrs mapping.
2. Singleton reproducer claim: when the only xarray attrs list entry is from `cond`, scalar `x` still returns empty attrs rather than indexing a missing second entry.
3. Two-entry scalar claim: when `cond` and `y` both contribute attrs but scalar `x` does not, the attrs selector still returns empty attrs and does not use `y` as a fallback.
4. X-source preservation claim: when a current merge list contains attrs content that belongs to `x`, the selector returns attrs with that same content.
5. No-source claim: when a current merge list contains no attrs content from `x`, the selector returns empty attrs.
6. Frame claim: the fix changes only the `keep_attrs is True` adapter in `xr.where`; all other `keep_attrs` modes and the `apply_ufunc` call shape remain as before.
