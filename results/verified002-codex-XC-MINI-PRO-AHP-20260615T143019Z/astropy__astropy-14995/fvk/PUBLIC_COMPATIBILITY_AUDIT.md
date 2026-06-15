# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

None. V1 changes one private helper branch inside
`NDArithmeticMixin._arithmetic_mask` and does not change a public method
signature, return type shape, argument name, virtual dispatch protocol, or
storage format.

## Overrides and callsites

Search target inspected statically:

- `_arithmetic_mask` definitions under `repo/astropy`: only
  `repo/astropy/nddata/mixins/ndarithmetic.py`.
- `_arithmetic_mask` callsites under `repo/astropy`: only the internal caller in
  `_arithmetic` when `handle_mask` is callable.

No public subclass override needs a signature update.

## Compatibility conclusion

The change is behavior-only and narrows an erroneous exception/object-mask path
to the documented one-mask copy path. Existing callers that pass two present
masks still reach `handle_mask`; callers that pass `handle_mask=None` or
`"first_found"` are unchanged by V1.
