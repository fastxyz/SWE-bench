# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

V1 did not fully stand. The FVK audit found two issues:

- F3 / PO3: zero-valued Decimals need an explicit `number.is_zero()` path
  because adjusted-exponent arithmetic describes the first significant digit of
  a nonzero value.
- F4 / PO5 / PO6: the shortcut should be confined to the cutoff branch so
  existing fixed formatting, including normal Decimal subclass formatting, is
  not bypassed unnecessarily.

V2 updates `repo/django/utils/numberformat.py` accordingly.

## Recommended Follow-Up Tests

The task forbids editing tests, but these are the cases a future test pass
should cover:

1. `Decimal('1e-200')`, `decimal_pos=2` returns `'0.00'`.
2. `Decimal('0.' + '0' * 299 + '1234')`, `decimal_pos=3` returns `'0.000'`.
3. A zero-valued Decimal with a large exponent and large `decimal_pos` returns
   fixed zero rather than exponent notation.
4. A negative tiny Decimal keeps the same sign behavior as the existing fixed
   formatter.
5. A Decimal subclass with custom `__format__()` keeps ordinary non-cutoff
   formatting, and the cutoff shortcut preserves subclass formatting when a
   same-class zero can be constructed.
6. Large non-small values such as `Decimal('9e9999')` still use scientific
   notation.

## Open Risks

The formal proof abstracts Python `Decimal`, strings, and subclass constructors.
That is adequate for auditing the branch decision but not a substitute for a
full Django test run in a real environment.

The fallback for exotic Decimal subclasses whose constructor cannot accept
`"0"` or `"-0"` is intentionally conservative: it returns the plain zero shape
instead of failing. If Django needs stronger guarantees for arbitrary Decimal
subclasses, that should be specified separately.
