# FVK Notes

## Decisions and source changes

1. Kept V1's main `KeyTransformIn.resolve_expression_parameter()` approach.

   Trace: `fvk/PROOF_OBLIGATIONS.md` PO2, PO3, PO4, and PO7.

   Reason: FVK confirmed the per-element hook is the right abstraction boundary. It adapts direct literal RHS values while preserving inherited expression handling, native JSON handling, generic `None` removal, and subquery behavior.

2. Added an Oracle-specific `KeyTransformIn.split_parameter_list_as_sql()` branch.

   Trace: `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO6, PO7.

   Reason: V1 inlined Oracle RHS literals, producing SQL fragments with no RHS bind params. The inherited splitter chunks by `len(rhs_params)`, which becomes zero and cannot cover large RHS lists. The V2 branch chunks by RHS SQL fragment count only for Oracle's zero-param inline case and delegates all other cases back to the inherited splitter.

3. Added `_json_value_literal()` and used it from both `KeyTransformExact` and `KeyTransformIn`.

   Trace: `fvk/FINDINGS.md` F2 and `fvk/PROOF_OBLIGATIONS.md` PO5.

   Reason: Oracle string RHS values are explicitly in scope. Since the Oracle JSON helper embeds a JSON document in a SQL string literal, the proof obligation for all strings requires SQL single quotes to be doubled. The helper centralizes that behavior and preserves existing output for values without single quotes.

4. Kept generic `None` handling unchanged.

   Trace: `fvk/FINDINGS.md` F3 and `fvk/PROOF_OBLIGATIONS.md` PO7.

   Reason: The issue provides evidence for scalar values and Oracle strings, not a requirement to redefine generic SQL `IN` behavior for `None`. Changing that would be broader than the public intent.

5. Did not alter tests or run code.

   Trace: `fvk/FINDINGS.md` F4 and `fvk/PROOF_OBLIGATIONS.md` PO8.

   Reason: The task forbids modifying tests and forbids executing tests, Python, or K tooling. The proof artifacts include the exact commands that should be run later in a suitable environment.

## Artifact coverage

Required artifacts were written under `fvk/`:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy and formal-core artifacts were also written:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-django-json-lookup.k`
- `fvk/json-key-transform-in-spec.k`
