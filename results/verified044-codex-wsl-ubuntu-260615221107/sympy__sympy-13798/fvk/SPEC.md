# FVK Spec: sympy__sympy-13798

Status: constructed from public intent and source inspection; not
machine-checked. No tests, Python, or K tooling were run.

## Scope

The audited change is the `mul_symbol` setting path for SymPy's LaTeX printer:

- `repo/sympy/printing/latex.py`, `LatexPrinter.__init__`
- consumers of the derived settings in `_print_Mul`, `_print_Float`, and
  `_print_PolyElement`
- the public wrapper `latex(expr, **settings)` as the entry point that accepts
  `mul_symbol`

The proof does not model all LaTeX printing. It models the separator derivation
and the fact that the consumers use the derived separator strings.

## Intent Spec

I-01. Public issue intent: `latex()` accepts a `mul_symbol` kwarg, and users
should be able to supply a choice outside the historical set. This makes
non-legacy custom LaTeX strings in-domain for `mul_symbol`.

I-02. Public issue example: the motivating custom value is `r"\,"`, a LaTeX thin
space. The expected observable is that products can be printed with a thin-space
separator.

I-03. Public hint: "an unknown argument is used as the latex." This means a
custom value is a complete separator string. It should not be looked up in the
legacy table, rejected, rewritten to a new alias, or automatically padded with
ASCII spaces.

I-04. Public compatibility intent: the proposed change is described as
"backwards-compatible." Existing values `None`, `"ldot"`, `"dot"`, and
`"times"` must keep their previous meanings.

I-05. Source comment compatibility: `_print_Float` says scientific notation
"must always have a mul symbol" and uses the numeric separator. Existing default
behavior for `mul_symbol=None` therefore preserves `\cdot` between mantissa and
power of ten.

## Public Evidence Ledger

E-01. Source: prompt. Quote: "`mul_symbol` kwarg that must be one of four
choices. I would like to be able to supply my own choice." Obligation: widen the
accepted value domain for `mul_symbol` beyond the historical aliases. Status:
encoded by PO-02.

E-02. Source: prompt. Quote: "I want the multiplication symbol to be `\,`."
Obligation: `r"\,"` is a valid custom separator. Status: encoded by PO-02 and
PO-04.

E-03. Source: public hint. Quote: "an unknown argument is used as the latex."
Obligation: a custom value is used literally as the separator. Status: encoded
by PO-02.

E-04. Source: prompt. Quote: "backwards-compatible." Obligation: preserve
legacy alias behavior. Status: encoded by PO-01 and PO-03.

E-05. Source: implementation comment. Quote: "Must always have a mul symbol."
Obligation: preserve the default `None` numeric separator behavior. Status:
encoded by PO-03 and PO-05.

## Formal Model

Let `m` be the public `mul_symbol` setting after normal printer setting merging.
The formal domain for this issue is `m in {None} union String`.

Legacy table:

- `None -> " "`
- `"ldot" -> r" \,.\, "`
- `"dot" -> r" \cdot "`
- `"times" -> r" \times "`

Resolved separators:

- `mul_symbol_latex = legacy[m]` when `m` is one of the legacy keys.
- `mul_symbol_latex = m` when `m` is any other string.
- `mul_symbol_latex_numbers = legacy["dot"]` when `m is None`.
- `mul_symbol_latex_numbers = mul_symbol_latex` otherwise.

Consumer obligations:

- `_print_Mul` must use `mul_symbol_latex` between ordinary adjacent factors
  and `mul_symbol_latex_numbers` between adjacent numeric terms.
- `_print_Float` must use `mul_symbol_latex_numbers` for scientific notation.
- `_print_PolyElement` must pass `mul_symbol_latex` to polynomial factor
  joining.

## Adequacy Audit

The formal model is adequate for this issue because the reported defect is the
initial separator derivation. The downstream printers already consume derived
strings, so modeling the complete expression printer is unnecessary for the
property under audit.

The model deliberately treats custom values as complete separators. This follows
E-03. If a caller wants normal spaces around a thin-space command, the in-domain
custom value is `r" \, "`.

## Compatibility Audit

No public signature changed. `latex(expr, **settings)` still accepts keyword
settings. `LatexPrinter.__init__(settings=None)` still accepts a settings dict.
The accepted value domain of the existing `mul_symbol` key is widened.

Public consumers searched in source:

- `_print_Mul` consumes `mul_symbol_latex` and `mul_symbol_latex_numbers`.
- `_print_Float` consumes `mul_symbol_latex_numbers`.
- `_print_PolyElement` consumes `mul_symbol_latex`.
- `poly.str` receives the separator and joins factors with it.

No subclass override or public callsite requires a signature update.
