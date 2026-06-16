# Public Compatibility Audit

Status: static source audit; no tests or code executed.

## Changed Symbol

`xarray.coding.variables.UnsignedIntegerCoder.decode(self, variable, name=None)`

## Signature

Unchanged.

## Return Shape

Unchanged: returns `Variable(dims, data, attrs, encoding)`.

## Public Callers

- `xarray.conventions.decode_cf_variable` constructs
  `variables.UnsignedIntegerCoder()` and calls `.decode(var, name=name)` before
  `CFMaskCoder` and `CFScaleOffsetCoder`.
- `xarray.conventions.decode_cf_variables` routes dataset variables through
  `decode_cf_variable`.
- Backend entrypoints, including pydap, pass variables into this shared decode
  path through the existing store API.

## Compatibility Result

Pass. V2 does not change public signatures, dispatch shape, backend APIs, or
return object shape. It only changes the interpretation of explicit `_Unsigned`
markers for integer arrays.

## Producer/Consumer Check

The producer side for pydap attributes remains unchanged:
`PydapDataStore.open_store_variable` passes `_fix_attributes(var.attributes)` to
`Variable`. The consumer side now decodes both string and explicit boolean
markers in `UnsignedIntegerCoder.decode`.
