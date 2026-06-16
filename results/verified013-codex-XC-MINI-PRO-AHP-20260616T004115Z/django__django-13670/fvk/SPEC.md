# FVK Spec: django__django-13670

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 change to `django.utils.dateformat.DateFormat.y()`
and the direct observable `django.utils.dateformat.format(value, "y")`. It does
not attempt to verify all Django date formatting tokens or the entire template
filter stack. The frame condition is that the patch changes only the `y` token's
output for years whose last two digits were not already produced correctly.

## Intent Specification

For any supported Python `datetime.date` or `datetime.datetime` object, the
Django date format character `y` must return the year as exactly two decimal
digits, equal to the last two digits of the full year and left-padded with zero
when needed.

Let `Y` be `value.year`, with the Python `datetime` domain `1 <= Y <= 9999`.
Let `R = Y % 100`. The required result is the two-character decimal string:

- first character: decimal digit `R // 10`
- second character: decimal digit `R % 10`

Examples required by the intent include:

- `Y = 123` -> `"23"`
- `Y = 9` -> `"09"`
- `Y = 99` -> `"99"`
- `Y = 100` -> `"00"`
- `Y = 1979` -> `"79"`
- `Y = 1000` -> `"00"`

The `Y` token remains the four-digit year token and is out of scope for change.

## Public Evidence Ledger

### E-001: Issue title

- Source: prompt / public issue
- Quoted evidence: `dateformat.y() doesn't support years < 1000.`
- Semantic obligation: the `y` formatter must be correct for years below 1000.
- Status: encoded in OBL-002 through OBL-004.

### E-002: Issue examples and comparator behavior

- Source: prompt / public issue
- Quoted evidence: Django produced `"3"` for `datetime.datetime(123, 4, 5, 6, 7)`
  with format `"y"`, while Python `strftime("%y")` and PHP `date("y")` produced
  `23`.
- Semantic obligation: `Y = 123` must produce the two-digit value `"23"`, not the
  one-digit suffix of the non-padded year string.
- Status: encoded in OBL-003 and Finding F-001.

### E-003: Issue boundary language

- Source: prompt / public issue
- Quoted evidence: `date before 999 (or 99 and 9 for similar matters) and the
  format character "y" no leading zero will be printed.`
- Semantic obligation: the fix must cover the family of small-year boundaries,
  including one-, two-, and three-digit years, not only the concrete year 123.
- Status: encoded in OBL-004 and Finding F-002.

### E-004: Django docs for the date filter

- Source: docs
- Quoted evidence: `y` is documented as `Year, 2 digits.`
- Semantic obligation: output width for `y` is exactly two digits.
- Status: encoded in OBL-002.

### E-005: Django docs for PHP-like date format syntax

- Source: docs
- Quoted evidence: Django `Uses a similar format as PHP's date() function`
  and the format characters were designed to be compatible with PHP.
- Semantic obligation: interpreting `y` as PHP-style two-digit year is supported
  by public API documentation.
- Status: supports OBL-002 and OBL-003.

### E-006: Existing public test for ordinary years

- Source: public in-repository test
- Quoted evidence: `dateformat.format(my_birthday, 'y') == '79'` for year 1979.
- Semantic obligation: preserve ordinary four-digit behavior for existing
  public test coverage.
- Status: encoded in OBL-005 and Finding F-003.

### E-007: Current V1 implementation

- Source: implementation
- Quoted evidence: `return '%02d' % (self.data.year % 100)`
- Semantic obligation: candidate mechanism to check against the intent-derived
  contract; it is not itself the source of the expected behavior.
- Status: checked by OBL-002 through OBL-005.

## Formal Model

The formal core is in:

- `fvk/mini-python-dateformat.k`
- `fvk/dateformat-y-spec.k`

The mini semantics models only the changed expression:

```text
DateFormat.y(Y) = pad2(Y % 100)
pad2(N) = exactly two decimal digits for 0 <= N <= 99
```

The formal observable uses `digits2(tens, ones)` instead of concrete strings.
This is property-complete for the defect because it distinguishes `"3"` from
`"23"` and `"9"` from `"09"` by requiring exactly two digit positions. The
rendering interpretation is `digits2(2, 3) == "23"` and
`digits2(0, 9) == "09"`.

## Contract

For all integers `Y` in the supported `datetime` year domain:

```text
1 <= Y <= 9999
DateFormat.y(Y) reaches digits2((Y % 100) // 10, (Y % 100) % 10)
```

No loops or recursion are present in the verified expression. Termination is
therefore a simple expression-evaluation obligation rather than a circularity.

## Frame Conditions

- `DateFormat.Y()` remains unchanged and still returns the full year.
- Other format characters remain unchanged.
- `Formatter.format()` dispatch mechanics remain unchanged: an unescaped `y`
  calls `DateFormat.y()` and joins the returned string representation into the
  final formatted result.
- Public method signatures are unchanged.
