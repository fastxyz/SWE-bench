# FVK Findings

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## F-RESOLVED-OUTER-MI

- Classification: code bug resolved by V1.
- Evidence: intent ledger entries `I1`, `I2`, and `I3`.
- Input: presentation printing of `Symbol("x2")`, and by composition
  `x2*z + x2**3`.
- Observed before V1: `_print_Symbol` created an outer `mi` and then appended an
  `msub`, yielding the shape `mi(msub(mi("x"), mi("2")))`.
- Expected: the top-level scripted symbol is `msub(mi("x"), mi("2"))`.
- V1 status: resolved. The subscript branch now constructs `msub` and returns it
  directly.
- Proof obligations: `PO-SUB-NO-OUTER-MI`, `PO-SPLIT-X2`, `PO-ISSUE-EXPR`.

## F-SCRIPTED-FAMILY

- Classification: code bug family resolved by V1.
- Evidence: the same invalid token-wrapper mechanism applies to all scripted
  presentation symbols because `_print_Symbol` used one outer `mi` before
  branching on `subs` and `supers`.
- Input family: `x_2`, `x2`, `x^2`, `x__2`, `x^3_2`, and names with multiple
  script parts such as `x_2_a`.
- Observed before V1: every scripted case returned an outer `mi` with `msub`,
  `msup`, or `msubsup` as its child.
- Expected: `msub`, `msup`, or `msubsup` is the top-level node.
- V1 status: resolved. V1 returns each scripted container directly.
- Proof obligations: `PO-SUB-NO-OUTER-MI`, `PO-SUP-NO-OUTER-MI`,
  `PO-SUBSUP-NO-OUTER-MI`, `PO-JOIN-SCRIPTS`.

## F-SUSPECT-LEGACY-SHAPE-TESTS

- Classification: suspect public-test evidence; no production-code change.
- Evidence: `repo/sympy/printing/tests/test_mathml.py` asserts that scripted
  presentation symbols have top-level `nodeName == 'mi'`.
- Conflict: the issue identifies an `mi` around a scripted presentation node as
  the bad shape. Under the FVK intent-evidence rule, tests encoding the reported
  bug are SUSPECT and must not veto the public intent.
- Expected action: do not preserve the old outer `mi`; do not edit tests in this
  benchmark. A normal upstream test update would change these assertions to
  expect `msub`, `msup`, or `msubsup` as the top-level node.
- Proof obligations: `PO-ADEQUACY-LEGACY-TEST-CONFLICT`.

## F-CONTENT-FRAME

- Classification: frame condition; no code bug found.
- Evidence: the problem uses `printer='presentation'` and its bad markup has
  unprefixed presentation tags. The content printer returns `ci` containers and
  was not the reported path.
- Decision: leave `MathMLContentPrinter._print_Symbol` unchanged.
- Proof obligations: `PO-CONTENT-FRAME`.

## F-BOLD-FRAME

- Classification: compatibility frame condition; no code bug found.
- Evidence: public tests show `mat_symbol_style="bold"` for a plain matrix
  symbol as `<mi mathvariant="bold">A</mi>`.
- Decision: V1 preserves this exact plain-symbol output. For scripted matrix
  symbols, V1 applies `mathvariant="bold"` to the base `mi`, avoiding the
  invalid outer wrapper while preserving the intended base-symbol styling.
- Proof obligations: `PO-PLAIN-FRAME`, `PO-BOLD-FRAME`.

## Residual Risks

- The proof is constructed over a mini MathML-node model, not machine-checked.
- Termination is not a meaningful concern for the audited branches: the function
  performs finite construction over finite script lists, but this FVK pass proves
  partial correctness only.
- Browser rendering is not proved. The code-level property is the emitted
  MathML shape identified by the issue.
