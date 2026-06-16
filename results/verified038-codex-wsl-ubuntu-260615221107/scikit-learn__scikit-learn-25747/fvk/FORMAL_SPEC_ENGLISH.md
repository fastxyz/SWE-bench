# Formal Spec in English

This file paraphrases every nontrivial claim in `set-output-spec.k`.

1. If `_wrap_data_with_container` is in pandas mode with automatic wrapping
   enabled and the data being wrapped is an existing `DataFrame`, then wrapping
   returns a `DataFrame` with the same payload, same columns when feature names
   are unavailable, and the same output `DataFrame` index, even when the
   original input index has a different row count.

2. If `_wrap_in_pandas_container` receives an existing `DataFrame` and resolved
   column names, it returns that `DataFrame` with updated columns and preserves
   the `DataFrame`'s existing index, even when the provided index length differs.

3. If `_wrap_in_pandas_container` receives an existing `DataFrame` and column
   name resolution raises, it preserves both the existing columns and the
   existing index.

4. If `_wrap_in_pandas_container` receives dense non-DataFrame output, it creates
   a new `DataFrame` using the supplied index and resolved columns.

5. If `_wrap_in_pandas_container` receives sparse output, it returns the modeled
   sparse error state corresponding to the production `ValueError`.

6. If `_wrap_data_with_container` is in default mode, it returns `data_to_wrap`
   unchanged.

7. If `_wrap_data_with_container` is in pandas mode but automatic wrapping is
   disabled, it returns `data_to_wrap` unchanged.

There are no loop circularities. The proof obligations are finite case splits
over object kind, output configuration, auto-wrap status, and column-resolution
result.
