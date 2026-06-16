# Constructed Proof

Status: constructed, not machine-checked. No executable checks were run.

## Adequacy Gate

The public intent is that `mul_symbol` remains backward-compatible while also
accepting arbitrary custom LaTeX strings. The formal obligations cover exactly
the observable path affected by the fix:

- separator derivation in `LatexPrinter.__init__`;
- product joining in `_print_Mul`;
- scientific notation joining in `_print_Float`;
- polynomial factor joining in `_print_PolyElement`;
- public API compatibility for `latex(expr, **settings)`.

No required behavior from `fvk/SPEC.md` is omitted. No obligation is derived
only from V1's current output.

## Proof Sketch

### PO-01

Case split on `mul_symbol`.

For `None`, `"ldot"`, `"dot"`, and `"times"`, V1 checks membership in
`mul_symbol_table` and assigns `mul_symbol_latex = mul_symbol_table[mul_symbol]`.
The table entries are unchanged from the pre-fix source. Therefore each legacy
alias resolves to the required old separator.

### PO-02

For any non-legacy string `s`, membership in `mul_symbol_table` is false. V1
takes the `else` branch and assigns `mul_symbol_latex = s`. There is no table
index on `s` in that branch, so the pre-V1 rejection path is removed for custom
strings. The specific motivating value `r"\,"` is a non-legacy string, so it
resolves to itself.

### PO-03

V1 assigns `mul_symbol_latex_numbers` with a separate case split. If
`mul_symbol is None`, it assigns `mul_symbol_table["dot"]`, preserving the old
numeric default `r" \cdot "`. Otherwise it assigns `mul_symbol_latex`, so aliases
and custom strings use the same separator for numeric products.

### PO-04

`_print_Mul` reads `separator = self._settings['mul_symbol_latex']` and
`numbersep = self._settings['mul_symbol_latex_numbers']`. The joining loop appends
`numbersep` only for adjacent numeric-looking rendered terms and appends
`separator` for other adjacent factors once output already exists. Therefore the
rendered factor list `["3", "x^{2}", "y"]` with `mul_symbol=r"\,"` joins as
`3\,x^{2}\,y`.

### PO-05

`_print_Float` reads `separator =
self._settings['mul_symbol_latex_numbers']`. In the scientific notation branch,
it returns `mantissa + separator + "10^{exp}"`. This directly discharges the
numeric-separator consumer obligation.

### PO-06

`_print_PolyElement` reads `mul_symbol =
self._settings['mul_symbol_latex']` and passes it to `poly.str`. In `poly.str`,
factor strings are joined with `mul_symbol.join(sexpv)`. Therefore polynomial
factor joining consumes the resolved separator.

### PO-07

The V1 source does not change `latex(expr, **settings)`,
`LatexPrinter.__init__(settings=None)`, or any printer method signature. It only
changes the value handling for an existing setting key. Existing public callers
continue to pass the same settings dict/kwargs shape.

### PO-08

This proof is a static construction only. The session did not run tests, Python,
or K tooling. The commands below are recorded but not executed.

## Machine-Check Commands

```sh
kompile fvk/mini-latex-mul-symbol.k --backend haskell
kast --backend haskell fvk/latex-mul-symbol-spec.k
kprove fvk/latex-mul-symbol-spec.k
```

Expected result after a real machine check: `kprove` discharges the claims to
`#Top`.

## Test Guidance

No tests were modified. Existing tests for legacy aliases should be kept unless
the K proof is later machine-checked and the project chooses to remove redundant
point tests. New useful tests would cover:

- `latex(2*x, mul_symbol=r"\,")`;
- `latex(3*x**2*y, mul_symbol=r" \, ")` for caller-controlled padding;
- legacy aliases `None`, `"ldot"`, `"dot"`, and `"times"`;
- scientific notation with default and custom `mul_symbol`.

All test-removal recommendations are conditioned on a future successful machine
check.

## Residual Risk

The proof abstracts away the full SymPy expression printer and models only the
separator derivation and joining sites. This is adequate for the reported bug
but does not prove unrelated LaTeX rendering behavior. The proof is constructed,
not machine-checked.
