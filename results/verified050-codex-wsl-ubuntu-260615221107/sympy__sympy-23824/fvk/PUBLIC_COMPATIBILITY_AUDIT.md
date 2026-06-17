# PUBLIC_COMPATIBILITY_AUDIT.md

Status: constructed, not machine-checked.

## Changed Public Symbols

None.

## `kahane_simplify`

- Signature: unchanged.
- Import path: unchanged.
- Return protocol: unchanged at the API level. The fix changes only the order
  of leading free gamma matrices in the previously buggy case.
- Public callers: no caller changes required because arguments and return type
  categories are unchanged.

## Compatibility Finding

No public compatibility issue found. This supports F-004 and PO-7.
