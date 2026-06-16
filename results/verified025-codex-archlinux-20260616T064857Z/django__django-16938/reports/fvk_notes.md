# FVK Notes

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Decision summary

V1 stands unchanged. The FVK audit found no additional source edit required for
the public intent in `benchmark/PROBLEM.md`.

## Decisions traced to FVK artifacts

1. Keep the `python.py` V1 change:
   `select_related(None).only("pk").iterator()`.

   Reason: F-001 identifies the pre-fix bug as inherited `select_related`
   surviving into the `only("pk")` query. PO-1 requires removing the reported
   `FieldError`; PO-2 requires preserving primary-key-only output; PO-3 requires
   using the actual clearing API. The V1 Python change satisfies all three.

2. Keep the `xml_serializer.py` V1 change.

   Reason: F-002 identifies XML as a duplicated non-natural-key m2m primary-key
   query path. PO-4 requires the serializer-family fix to cover both
   Python-derived serializers and XML. The XML change is justified even though
   the issue's reproduction used JSON, because the issue is about serialization
   of m2m primary-key references and XML has the same conflicting query shape.

3. Keep `select_related(None)`, not no-argument `select_related()`.

   Reason: F-003 records the ambiguity in the public hint. PO-3 resolves it from
   local ORM source evidence: `select_related(None)` clears the list, while
   no-argument `select_related()` enables traversal. No source change is needed.

4. Do not change the natural-key branch.

   Reason: F-004 and PO-5 frame this path as intentionally unchanged.
   Natural-key serialization does not combine `only("pk")` with
   `select_related`, and `natural_key()` may require non-primary-key fields.

5. Do not remove or modify tests, and do not claim machine-checked proof.

   Reason: F-005 and PO-7 are the honesty gate. The proof artifacts are
   constructed only; the benchmark also forbids test edits and execution.

## Artifacts produced

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-serializer-queryset.k`
- `fvk/serializer-m2m-spec.k`

## Residual risk

The formal model abstracts Django's full ORM to the query-state components that
produce the reported failure: selected relations, primary-key-only loading, and
related rows. That is enough for the issue-specific proof obligations, but not a
machine-checked proof of all serializer and ORM behavior.
