# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed symbols

`repo/lib/matplotlib/category.py`

- `StrCategoryConverter.convert(value, unit, axis)`
- `UnitData.update(data)`

## Signature and dispatch audit

No signatures changed. No new parameters, return types, converter registry
entries, virtual dispatch calls, or public storage formats were introduced.

Static callsite evidence:

- `Artist.convert_xunits` and `Artist.convert_yunits` continue to delegate to
  `Axis.convert_units`.
- `Axis.convert_units` continues to call `self.converter.convert(x, self.units,
  self)`.
- Category converter registration remains unchanged for `str`, `np.str_`,
  `bytes`, and `np.bytes_`.
- Public tests instantiate `StrCategoryConverter` and `UnitData` with the same
  method signatures.

## Compatibility conclusion

PO-7 passes. V1 changes only internal branch predicates, so public callers and
subclasses do not need updates.
