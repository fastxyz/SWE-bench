# Iteration Guidance

Status: V1 stands unchanged.

## Code

No further production-code edits are justified by the FVK findings. V1 already:

- preserves `split_super_sub` behavior for trailing digits;
- removes the invalid outer presentation `mi` for all scripted-symbol branches;
- preserves plain-symbol output;
- preserves `mat_symbol_style="bold"` for plain matrix symbols and applies the
  same base-symbol styling to scripted matrix symbols without reintroducing an
  invalid wrapper;
- leaves the content MathML printer unchanged because it is outside the reported
  presentation path.

## Tests

The benchmark forbids test edits, so no tests were changed. In a normal upstream
workflow, update old presentation-symbol tests that assert `nodeName == 'mi'`
for scripted symbols. Add regression coverage for:

- `mathml(Symbol("x2"), printer='presentation')` producing top-level `msub`;
- `mathml(Symbol("x_2"), printer='presentation')` producing top-level `msub`;
- `mathml(Symbol("x^2"), printer='presentation')` producing top-level `msup`;
- `mathml(Symbol("x^3_2"), printer='presentation')` producing top-level
  `msubsup`;
- `mathml(x2*z + x2**3, printer='presentation')` containing no `<mi><msub>`.

## Machine Check

The proof is constructed, not machine-checked. To check it later:

```sh
cd fvk
kompile mini-mathml.k --backend haskell
kast --backend haskell mathml-symbol-spec.k
kprove mathml-symbol-spec.k
```

Keep any test-removal decision conditional on `kprove` returning `#Top`.

## Next Human Question

No clarification is needed for this issue. The public issue gives both the bad
and corrected markup shape for the relevant presentation MathML.
