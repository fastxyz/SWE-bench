# FVK Proof Obligations

Status: constructed, not machine-checked.

## OBL-001: Intent-derived domain

- Statement: The verified domain for `DateFormat.y()` is any formatter whose
  `self.data.year` is an integer `Y` satisfying `1 <= Y <= 9999`.
- Evidence: Python `datetime.date` and `datetime.datetime` year domain, plus
  issue examples using Python `datetime`.
- Status: discharged by domain assumption in the K claim.
- Related findings: F-001, F-002.

## OBL-002: Exactly two output digits

- Statement: For every in-domain `Y`, the `y` token result has exactly two
  decimal digit positions.
- Evidence: E-004 (`Year, 2 digits.`), E-005 (PHP-like date syntax), and E-003
  (leading-zero problem).
- Formal shape: `digits2(T, O)` with `0 <= T <= 9` and `0 <= O <= 9`.
- Status: discharged by `%02d` in source and `pad2()` in the mini semantics.
- Related findings: F-001, F-002.

## OBL-003: Numeric content is the last two year digits

- Statement: For every in-domain `Y`, if `R = Y % 100`, the first digit is
  `R // 10` and the second digit is `R % 10`.
- Evidence: E-002 (`123 -> 23`) and E-005 (PHP/Python comparator behavior).
- Formal shape:
  `DateFormat.y(Y) => digits2((Y modInt 100) /Int 10, (Y modInt 100) modInt 10)`.
- Status: discharged by symbolic execution of `Y % 100` followed by `pad2`.
- Related findings: F-001, F-002.

## OBL-004: Boundary family coverage

- Statement: The contract covers one-, two-, three-, and four-digit years,
  including rollover values where the last two digits are `00`.
- Evidence: E-003.
- Representative derived cases: `1 -> "01"`, `9 -> "09"`, `99 -> "99"`,
  `100 -> "00"`, `123 -> "23"`, `999 -> "99"`, `1000 -> "00"`.
- Status: discharged by the single formula in OBL-003 over `1 <= Y <= 9999`.
- Related findings: F-002.

## OBL-005: Preserve ordinary-year behavior

- Statement: Existing expected behavior for ordinary four-digit years is
  preserved, for example `1979 -> "79"`.
- Evidence: E-006.
- Status: discharged because `1979 % 100 == 79` and width-two formatting leaves
  `"79"` unchanged.
- Related findings: F-003.

## OBL-006: Integration through `dateformat.format(value, "y")`

- Statement: When `Formatter.format()` sees an unescaped `y`, it calls
  `DateFormat.y()` and joins its string result into the output without changing
  the token's value.
- Evidence: source inspection of `Formatter.format()` dispatch and public
  tests using `dateformat.format(..., "y")`.
- Status: discharged by frame reasoning; V1 changed only `DateFormat.y()`.
- Related findings: F-003, F-004.

## OBL-007: No public API or unrelated token regression

- Statement: Public call shape, return shape, `Y`, and other date/time
  specifiers remain unchanged.
- Evidence: source diff shows a single expression-body change in
  `DateFormat.y()`.
- Status: discharged by diff inspection and compatibility audit.
- Related findings: F-004.

## OBL-008: Honesty gate for unrun K tooling

- Statement: The proof must be labeled constructed, not machine-checked, and
  tests must not be deleted or treated as confidently redundant unless future
  `kprove` execution returns `#Top`.
- Evidence: FVK `verify.md` honesty gate and user instruction not to run K
  tooling.
- Status: discharged by artifact labeling and by not editing tests.
- Related findings: F-005.
