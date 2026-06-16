# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and the proof obligations in `fvk/PROOF_OBLIGATIONS.md`.

## F-01: Pre-V1 custom `mul_symbol` rejection was the root bug

Input: `latex(2*x, mul_symbol=r"\,")`

Observed in pre-V1 source: `LatexPrinter.__init__` indexed
`mul_symbol_table[self._settings['mul_symbol']]`, so any non-legacy value raised
during printer initialization.

Expected from E-01 and E-03: an unknown string is in-domain and is used directly
as the LaTeX separator.

Status: fixed by V1. Covered by PO-02.

## F-02: Backward compatibility for legacy aliases is required and preserved

Input classes: `mul_symbol=None`, `"ldot"`, `"dot"`, and `"times"`.

Observed in V1 source: those keys still resolve through the same legacy mapping.

Expected from E-04: existing public alias behavior is unchanged.

Status: no V2 code change required. Covered by PO-01 and PO-03.

## F-03: Custom separator spacing is intentionally caller-controlled

Input: `latex(3*x**2*y, mul_symbol=r"\,")`

Expected from E-03: `r"\,"` is used as the complete separator, producing the
abstract joined form `3\,x^{2}\,y`. If a caller wants ASCII spaces around the
LaTeX command, the custom separator can be `r" \, "`.

Alternative considered: automatically wrap every custom separator with spaces.
Rejected because it contradicts the public hint that the unknown argument is
used as the LaTeX.

Status: V1 behavior is correct. Covered by PO-02 and PO-04.

## F-04: Numeric separator default remains special for `mul_symbol=None`

Input class: scientific-notation float printing with default `mul_symbol=None`.

Observed in V1 source: `mul_symbol_latex_numbers` remains `r" \cdot "` when
`mul_symbol is None`.

Expected from E-05 and backward compatibility: default scientific notation keeps
a visible multiplication separator.

Status: no V2 code change required. Covered by PO-03 and PO-05.

## F-05: Public compatibility risk is low

Input class: public calls to `latex(expr, mul_symbol=...)`.

Observed in V1 source: no function signature changed; only the accepted value
domain for an existing setting widened.

Expected from E-04: no caller or subclass update should be required.

Status: no V2 code change required. Covered by PO-07.

## F-06: Verification is constructed, not machine-checked

Input: the FVK K artifacts and commands.

Observed in this session: the task forbids running tests, Python, `kompile`, or
`kprove`.

Expected from FVK honesty gate: artifacts must be labeled constructed, not
machine-checked, and test removal must remain recommendation-only.

Status: residual verification risk. Covered by PO-08.
