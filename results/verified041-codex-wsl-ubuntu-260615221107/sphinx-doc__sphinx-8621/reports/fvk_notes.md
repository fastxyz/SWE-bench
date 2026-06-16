# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found that the V1 positional tokenizer
satisfies the public separator-as-key intent for the verified `KeyboardSeq`
domain, and no finding justified a source edit.

## Decisions Traced to Findings and Obligations

1. Kept `repo/sphinx/builders/html/transforms.py` unchanged.

   Trace: F-1 is closed by PO-2, which proves standalone `-`, `+`, and `^`
   tokenize as single key parts. F-2 is closed by PO-4, which proves punctuation
   separators in key position are key text in compounds such as `Shift-+` and
   `Control++`. PO-6 proves `run()` leaves one-part tokenizations as one outer
   `kbd` element and emits nested key nodes only for multi-part compounds.

2. Preserved existing ordinary compound behavior.

   Trace: F-3 is confirmed by PO-3 and PO-7. The V1 parser still tokenizes
   `Control+X` and `M-x  M-s` into the existing key/separator sequence, and no
   public registration, builder, writer, or command API changed.

3. Did not add extra recovery behavior for malformed adjacent separators.

   Trace: F-4 records `Shift- +`-style inputs as underspecified. PO-1 fixes the
   proof domain from public intent as `KeyboardSeq`, which requires a key after
   each separator. Because the public issue does not define adjacent mixed
   separators or missing key text, changing source behavior for that shape
   would exceed the justified obligation.

4. Added FVK artifacts under `fvk/`.

   Trace: PO-8 requires the constructed proof package and honesty gate. The
   requested artifacts are `fvk/SPEC.md`, `fvk/FINDINGS.md`,
   `fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and
   `fvk/ITERATION_GUIDANCE.md`. I also added the FVK adequacy/compatibility
   support files and K-style artifacts required by the kit documentation:
   `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
   `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`,
   `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`, `fvk/mini-keyboard.k`, and
   `fvk/keyboard-transform-spec.k`.

5. Did not run tests, Python, or K tooling and did not edit tests.

   Trace: F-5 and PO-8 mark the proof as constructed, not machine-checked. The
   task explicitly forbids execution and test-file edits, so the proof commands
   are recorded in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md` but were not
   executed.

## Residual Risk

The proof is not machine-checked in this environment. The remaining semantic
uncertainty is limited to malformed key-sequence text outside the public
`KeyboardSeq` domain. Future work should clarify F-4 before changing behavior
for those inputs.
