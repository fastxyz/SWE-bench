# Formal Spec in English

Status: paraphrase of `xarray-variable-spec.k`; constructed, not
machine-checked.

FSE1. `ARBITRARY-VALUES-PRESERVED`: For any arbitrary object represented as
`arbitraryValuesObject(PAYLOAD)`, `as_compatible_data` returns an object array
containing the original arbitrary object, not the payload behind `.values`.

FSE2. `SCALAR-SETITEM-PRESERVES-ARBITRARY-VALUES-OBJECT`: Scalar setitem
through the modeled xarray assignment path delegates to `as_compatible_data` and
therefore preserves an arbitrary `.values` object as the assignment value.

FSE3. `SCALAR-DATAARRAY-CONSTRUCT-PRESERVES-ARBITRARY-VALUES-OBJECT`: Scalar
`DataArray(..., dims=[])` construction delegates to `as_compatible_data` and
therefore preserves an arbitrary `.values` object as the array payload.

FSE4. `KNOWN-CONTAINER-UNWRAPS-VALUES`: Known self-described containers
represented as `knownValuesContainer(PAYLOAD)` are intentionally unwrapped to
their values payload and converted as array data.

FSE5. `VARIABLE-AND-ADAPTER-FRAME`: Existing direct `Variable` data extraction
and existing supported non-NumPy adapter wrapping are unchanged.

FSE6. `PRE-V1-BUG-CHARACTERIZATION`: The pre-V1 generic `.values` step maps an
arbitrary `.values` object to the payload rather than to the object. This is a
bug characterization, not desired behavior.

FSE7. The proof is partial correctness over the modeled helper paths. It does
not claim total correctness for NumPy/pandas internals and has not been
machine-checked.
