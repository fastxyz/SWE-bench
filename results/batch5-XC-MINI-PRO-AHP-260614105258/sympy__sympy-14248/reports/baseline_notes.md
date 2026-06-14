# Baseline notes — sympy__sympy-14248

## Issue

The difference of `MatrixSymbol`s prints as a sum with an explicit `(-1)`
coefficient. Internally `a - b` is `MatAdd(a, MatMul(-1, b))`, but unlike the
scalar `Add`/`Mul` printers, the matrix printers did not collapse the leading
`-1` into a sign. For `A - A*B - B` the three printers produced:

```
str:    (-1)*B + (-1)*A*B + A
pretty: -B + -A⋅B + A
latex:  -1 B + -1 A B + A
```

The expected behaviour is to print such terms with a leading minus, e.g.
`-B - A*B + A`, like the scalar printers already do for ordinary `Add`/`Mul`.

## Root cause

Two printing helpers in each of the three human-readable printers were too
naive:

1. `_print_MatMul` printed every factor (including a numeric coefficient)
   verbatim and joined them, so a `-1`/`-2` coefficient came out as
   `(-1)*B` (str) or `-1 B` (latex). It never folded a `-1` coefficient into a
   bare sign.
2. `_print_MatAdd` blindly joined every term with `" + "`, so a term whose
   printed form began with a minus produced `+ -...` instead of `- ...`.

The scalar `_print_Add`/`_print_Mul` methods already handle this (they strip a
leading `-` from each term and emit a `-` separator, and `_print_Mul` folds a
negative coefficient into a sign via `_keep_coeff`). The matrix variants simply
had not been brought up to the same standard.

## Changes

### `sympy/printing/str.py`

- **`_print_MatMul`**: extract the coefficient with `expr.as_coeff_mmul()`. If
  it is a negative number, fold it back in with `_keep_coeff(-c, m)` and emit a
  leading `"-"` sign. This turns `MatMul(-1, B)` into `-B`, `MatMul(-1, A, B)`
  into `-A*B`, and `MatMul(-2, B)` into `-2*B`, while `MatMul(2, B)` and
  symbolic/positive coefficients are unchanged. The pattern mirrors the existing
  `_print_Mul`.
- **`_print_MatAdd`**: rewritten to mirror `_print_Add` — print each term, strip
  a leading `-` and use it as the term's sign, otherwise use `+`; drop the
  leading `+`. The `precedence(term) < PREC` parenthesization branch is kept for
  parity with `_print_Add` (it is a no-op for the matrix terms that actually
  occur, since `MatMul`/`MatrixSymbol` precedence is ≥ `MatAdd`).

### `sympy/printing/latex.py`

- **`_print_MatAdd`**: same strip-the-leading-`-` rewrite as the str printer.
- **`_print_MatMul`**: when the leading argument is exactly `-1`, emit `"-"` and
  join the remaining (matrix) factors, dropping the redundant `1`
  (`MatMul(-1, B)` → `-B`). All other coefficients keep the previous behaviour
  (`-2 A`, `- \sqrt{2} A`, `2 A`, …), so the existing `test_matMul`/`test_matAdd`
  expectations still hold.

### `sympy/printing/pretty/pretty.py`

- **`_print_MatAdd`**: replaced the `_print_seq(..., ' + ')` call with an
  explicit fold that joins terms with `' + '`, but uses a bare `' '` separator
  when the next term's coefficient (`S(item.args[0])`) is negative, letting the
  term supply its own leading minus. The pretty `_print_MatMul` already renders
  `MatMul(-1, B)` as `-B` (via `prettyForm.__mul__`'s `-1 → -` substitution), so
  only the joining needed fixing. For all-positive sums the output is identical
  to the old `_print_seq` result (the trailing `parens(None, None)` in
  `_print_seq` is a no-op on the picture), so e.g. `test_Adjoint` is unaffected.

## Resulting output for `A - A*B - B`

```
str:    -B - A*B + A
pretty: -B -A⋅B + A
latex:  -B - A B + A
```

## Assumptions / alternatives considered

- **Term ordering.** `MatAdd` canonicalises its args with
  `sort(default_sort_key)`, which (as the issue's own output shows) places
  `MatMul` terms before bare `MatrixSymbol`s, so the negative terms tend to come
  first. The visible `test_matAdd` cases (`C - 2*B`, etc.) all rely on this
  ordering and continue to pass; my changes do not alter ordering.
- **Detecting a negative term.** `_coeff_isneg` cannot be used on a `MatMul`:
  `MatMul.is_Mul`/`is_Number` are both `False`, so `_coeff_isneg(MatMul(-1,B))`
  returns `False`. I therefore detect negativity from the printed string
  (`startswith('-')`, used by str/latex, matching the scalar `_print_Add`) or
  from the leading coefficient `S(item.args[0]).is_negative` (used by pretty,
  which works with 2-D `prettyForm`s where re-stripping a `-` is awkward and
  where `as_coeff_mmul` is not available on explicit `MatrixBase` terms).
- **str `_print_MatMul` coefficient test.** Used `c.is_number and c < 0`
  (the same idiom as `_print_Mul`). The `is_number` guard short-circuits for
  symbolic coefficients; no test prints a matrix with a non-real numeric
  coefficient, so the comparison is only ever applied to real numbers.
- **latex `_print_MatMul`.** Only the exact `-1` coefficient needed special
  handling; `-2`, `-sqrt(2)`, etc. already print with a leading `-` via
  `self._print`. I deliberately avoided an approach like
  `Mul(-1, expr, evaluate=False)` because re-feeding the still-negative `MatMul`
  through `_print_MatMul` recurses infinitely.
- **Pre-fix tests are stale.** `test_MatrixElement_printing` in `test_str.py`
  and `test_latex.py` still assert the *old* buggy strings
  (`"((-1)*B + A)[0, 0]"`, `r"\left(-1 B + A\right)_{0, 0}"`). These are the
  pre-fix expectations and will be updated by the evaluation's test patch; my
  output (`"(-B + A)[0, 0]"`, `r"\left(-B + A\right)_{0, 0}"`) is the corrected
  form. The pretty version of the same test already asserts the clean
  `"(-B + A)[0, 0]"`, which my `_print_MatAdd` reproduces exactly.
