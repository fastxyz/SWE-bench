# FVK Specification: Presentation MathML Scripted Symbols

Status: constructed, not machine-checked. This specification audits the V1 fix
for `sympy__sympy-15976`.

## Scope

Primary unit under audit:

- `repo/sympy/printing/mathml.py`
  `MathMLPresentationPrinter._print_Symbol(sym, style='plain')`

Supporting implementation fact:

- `repo/sympy/printing/conventions.py` `split_super_sub(text)` treats a name
  ending in ASCII letters followed by digits, such as `x2`, as base `x` with
  subscript `2`.

Out of scope by public intent:

- `MathMLContentPrinter._print_Symbol`, because the reported bad markup was
  emitted with `printer='presentation'` and uses presentation tags without the
  content printer's `ci` token.
- Browser rendering behavior after valid MathML is emitted. The code obligation
  is the emitted MathML shape.

## Public Intent Ledger

### I1: Bug report title

- Source: prompt / issue.
- Evidence: "A symbol ending with a number is made invisible when printing with
  MathML".
- Obligation: presentation MathML for a symbol such as `x2` must not use a
  structure known to make the symbol disappear in Safari.
- Status: encoded by `PO-SUB-NO-OUTER-MI` and `PO-ISSUE-EXPR`.

### I2: Positive corrected markup

- Source: prompt / issue hints.
- Evidence: the issue identifies `<mi><msub><mi>r</mi><mi>2</mi></msub></mi>`
  as erroneous and says removing the outer `mi` gives
  `<msub><mi>r</mi><mi>2</mi></msub>`.
- Obligation: when a presentation symbol has a subscript, the top-level node is
  `msub`, not an `mi` containing `msub`.
- Status: encoded by `PO-SUB-NO-OUTER-MI`.

### I3: Full observable expression

- Source: prompt / issue HTML snippet.
- Evidence: the generated expression for `x2*z + x2**3` contains two
  occurrences of `<mi><msub><mi>x</mi><mi>2</mi></msub></mi>`, one in the
  product and one in the power base.
- Obligation: the fix must apply wherever `_print_Symbol(x2)` contributes to a
  larger presentation tree, not only when the symbol is printed by itself.
- Status: encoded by `PO-ISSUE-EXPR` and the proof composition step.

### I4: Trailing digits remain subscripts

- Source: implementation comment in `split_super_sub`.
- Evidence: "make a little exception when a name ends with digits, i.e. treat
  them as a subscript too."
- Obligation: the fix must not change `x2` into literal text `x2`; it must keep
  the subscript interpretation and only remove the invalid outer token wrapper.
- Status: encoded by `PO-SPLIT-X2`.

### I5: Legacy public tests are suspect

- Source: in-repo public tests.
- Evidence: `repo/sympy/printing/tests/test_mathml.py` expects
  `mpp._print(Symbol("x_2")).nodeName == 'mi'` with child `msub`.
- Obligation: because the public issue identifies this wrapper shape as the bug,
  these old shape assertions are SUSPECT legacy evidence and must not override
  the issue-derived spec.
- Status: recorded in `fvk/FINDINGS.md` as `F-SUSPECT-LEGACY-SHAPE-TESTS`.

### I6: Existing non-script behavior is preserved

- Source: public tests and API names.
- Evidence: plain symbols print as `<mi>x</mi>`; `mat_symbol_style="bold"` prints
  a plain matrix symbol as `<mi mathvariant="bold">A</mi>`.
- Obligation: plain presentation symbols and public settings remain compatible.
- Status: encoded by `PO-PLAIN-FRAME` and `PO-BOLD-FRAME`.

## Contract

Let `split_super_sub(sym.name)` produce `(base, supers, subs)` and let the MathML
presentation printer translate Greek names in each component exactly as before.
Let `join(items)` be the existing script-list renderer: one item becomes
`<mi>item</mi>`; multiple items become an `<mrow>` alternating `<mi>item</mi>`
and a space `<mo> </mo>`.

For `MathMLPresentationPrinter._print_Symbol(sym, style)`:

1. If `supers` and `subs` are empty, return `mi(base)`.
2. If `subs` is nonempty and `supers` is empty, return
   `msub(mi(base), join(subs))`.
3. If `supers` is nonempty and `subs` is empty, return
   `msup(mi(base), join(supers))`.
4. If both are nonempty, return
   `msubsup(mi(base), join(subs), join(supers))`.
5. If `style == 'bold'`, the base `mi(base)` has `mathvariant="bold"`;
   script components are rendered as before.
6. No returned scripted-symbol node is wrapped in an additional outer `mi`.

## Adequacy Summary

The formal claims in `fvk/mathml-symbol-spec.k` state the same contract over an
abstract MathML-node model. The model distinguishes a passing node
`MSUB(MI("x", false), MI("2", false))` from the failing node
`MIWRAP(MSUB(MI("x", false), MI("2", false)))`, so it preserves the exact
observable property that the issue reports.

The audit conclusion is that V1 stands unchanged: its implementation returns
the scripted node directly in every scripted branch and preserves the plain
symbol branch.
