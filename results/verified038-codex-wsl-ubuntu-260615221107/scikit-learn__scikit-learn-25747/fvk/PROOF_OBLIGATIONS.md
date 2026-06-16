# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Aggregated DataFrame Index Preservation

For any pandas output auto-wrap call where `data_to_wrap` is already a
`DataFrame`, the output index must equal the `DataFrame`'s existing index, not
the original input index. This must hold even when the output row count differs
from the original input row count.

Evidence: E1-E4. Formal claim: first claim in `set-output-spec.k`.

## PO-2: DataFrame Column Update Frame

When resolved column names are available for an existing `DataFrame`, the
wrapper may update columns but must preserve the existing index.

Evidence: E4-E5. Formal claim: second claim in `set-output-spec.k`.

## PO-3: Callable Column Failure Frame

When a column-name callable raises, the wrapper treats columns as unavailable.
For an existing `DataFrame`, both columns and index are preserved.

Evidence: helper docstring and current source. Formal claim: third claim in
`set-output-spec.k`.

## PO-4: Non-DataFrame Output Uses Supplied Index

When wrapping dense non-DataFrame output, the wrapper constructs a new
`DataFrame` with the supplied/original index. This preserves ordinary same-row
transformer behavior.

Evidence: E3 plus existing API behavior. Formal claim: fourth claim in
`set-output-spec.k`.

## PO-5: Sparse Output Rejection

Sparse data remains unsupported for pandas output and raises the same error.

Evidence: E6. Formal claim: fifth claim in `set-output-spec.k`.

## PO-6: `_wrap_data_with_container` Frame Conditions

Default output and pandas output with auto wrapping disabled return
`data_to_wrap` unchanged.

Evidence: current source and API frame requirement. Formal claims: final two
claims in `set-output-spec.k`.

## PO-7: Adequacy and Compatibility

The formal claims must not prove a legacy behavior contradicted by public issue
intent, and the source change must not alter public signatures or unsupported
sparse behavior.

Evidence: `SPEC_AUDIT.md` and `PUBLIC_COMPATIBILITY_AUDIT.md`.
