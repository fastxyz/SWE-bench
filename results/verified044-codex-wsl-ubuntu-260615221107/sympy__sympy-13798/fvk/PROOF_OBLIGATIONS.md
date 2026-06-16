# Proof Obligations

Status: constructed, not machine-checked. The K-style formal core is in
`fvk/mini-latex-mul-symbol.k` and `fvk/latex-mul-symbol-spec.k`.

## PO-01: Legacy alias resolution

For `mul_symbol` values in the legacy domain, `LatexPrinter.__init__` must set:

- `None -> mul_symbol_latex == r" "`
- `"ldot" -> mul_symbol_latex == r" \,.\, "`
- `"dot" -> mul_symbol_latex == r" \cdot "`
- `"times" -> mul_symbol_latex == r" \times "`

Evidence: E-04. Finding trace: F-02.

## PO-02: Custom separator resolution

For every string `s` where `s not in {"ldot", "dot", "times"}`,
`LatexPrinter.__init__` must set `mul_symbol_latex == s`.

This obligation includes `s == r"\,"`.

Evidence: E-01, E-02, E-03. Finding trace: F-01, F-03.

## PO-03: Numeric separator resolution

`LatexPrinter.__init__` must set:

- `mul_symbol_latex_numbers == r" \cdot "` when `mul_symbol is None`.
- `mul_symbol_latex_numbers == mul_symbol_latex` otherwise.

Evidence: E-04, E-05. Finding trace: F-02, F-04.

## PO-04: Product joining consumes the resolved separators

For a multiplication expression whose rendered factors are `f1, ..., fn`:

- ordinary adjacent factors are joined with `mul_symbol_latex`;
- adjacent numeric-looking factors are joined with `mul_symbol_latex_numbers`.

In particular, with rendered factors `["3", "x^{2}", "y"]` and
`mul_symbol=r"\,"`, the abstract joined form is `3\,x^{2}\,y`.

Evidence: E-02, E-03. Finding trace: F-03.

## PO-05: Scientific notation consumes the numeric separator

For a float rendered in scientific notation, the mantissa and power-of-ten term
must be joined by `mul_symbol_latex_numbers`.

Evidence: E-05. Finding trace: F-04.

## PO-06: Polynomial factor joining consumes the resolved separator

For polynomial element printing, factor strings must be joined with
`mul_symbol_latex`, passed to `poly.str`.

Evidence: E-01, E-03. Finding trace: F-01.

## PO-07: Public compatibility

The fix must not change public function signatures, remove legacy settings, or
require public callsite updates. It may only widen the value domain of the
existing `mul_symbol` setting.

Evidence: E-04. Finding trace: F-05.

## PO-08: Honesty gate

The proof artifacts must be labeled constructed, not machine-checked. Tests and
K tooling must not be run in this benchmark session.

Evidence: task constraints and FVK verify honesty gate. Finding trace: F-06.

## Commands To Machine-Check Later

Do not run these in this benchmark session. They are recorded for a future
environment with K installed:

```sh
kompile fvk/mini-latex-mul-symbol.k --backend haskell
kast --backend haskell fvk/latex-mul-symbol-spec.k
kprove fvk/latex-mul-symbol-spec.k
```
