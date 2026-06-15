# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Source Decision

Keep V1 unchanged.

Rationale:

- F1 and F2 identify the two public-intent failures.
- The current V1 patch directly resolves them.
- PO1 through PO6 compose to the intended round-trip value preservation property.
- PO7 confirms the patch does not alter public APIs, header grouping, formatting,
  or test files.

## Recommended Tests For A Future Test-Editing Setting

Do not modify tests in this task. In a normal development setting, add focused
tests for:

1. `fits.Card.fromstring(str(fits.Card("CONFIG", "x" * n + "''"))).value`
   equals the original observed value for boundary lengths around 60-70.
2. `fits.Card.fromstring(str(fits.Card("CONFIG", "x" * n + "''" + "x" * 10))).value`
   equals the original observed value for boundary lengths around 50-70.
3. `fits.Card.fromstring(fits.Card("FOO", "x" * 100 + "''", "comment").image).value`
   preserves both logical quotes.
4. `fits.Card.fromstring(fits.Card("FOO", "x" * 100 + "'' aaa", "comment").image).value`
   preserves the doubled quote, the space, and the trailing text.
5. Existing long-value comments still round trip and preserve the documented
   behavior that `&` is not part of the value.

## Machine-Check Follow-Up

The proof is constructed only. If K tooling is available later, run:

```sh
kompile fvk/mini-fits-card.k --backend haskell
kast --backend haskell fvk/fits-card-spec.k
kprove fvk/fits-card-spec.k
```

Keep all tests until the proof is machine-checked and the real test suite also
passes.

## Future Spec Boundary

F4 records a residual parser-wide risk: the existing FITS string regex is
documented in comments as lenient around odd quote counts. A broader parser
rewrite should not be bundled into this issue fix without a new public intent
ledger because it could affect compatibility with non-standard FITS headers.

## Prompt For A Future Repair Pass

If a future run broadens the scope beyond this issue, ask:

```
Should Astropy preserve backward-compatible parsing of malformed FITS string
cards with odd or ambiguous quote counts, or should those cards become
VerifyError cases under a stricter FITS grammar?
```
