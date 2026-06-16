# FVK Notes

## Summary

The FVK audit did not leave V1 unchanged. It confirmed V1's core registration
fix, but found one V1 compatibility regression in the `:term:` role target
shape. V2 keeps exact glossary-term object registration and revises the role
path so local resolution can use original spelling while the public pending
reference target remains lowercased.

## Decisions

1. Keep exact glossary-term registration.

- Trace: `fvk/FINDINGS.md` F-001.
- Obligations: `fvk/PROOF_OBLIGATIONS.md` PO-001, PO-002, PO-003.
- Decision: `make_glossary_term()` continues to call
  `std.note_object('term', termtext, node_id, location=term)`.
- Reason: exact keys prevent `MySQL` and `mysql` from colliding while preserving
  the unchanged exact-duplicate warning path in `StandardDomain.note_object()`.

2. Repair V1's `:term:` role compatibility regression.

- Trace: `fvk/FINDINGS.md` F-002.
- Obligations: PO-004 and PO-005.
- Decision: add `TermXRefRole`. It stores the normalized original target in
  `pending_xref['std:term-original']` but returns `target.lower()` as the public
  `reftarget`.
- Reason: V1 removed lowercasing entirely, which would change the
  pre-resolution target consumed by intersphinx. V2 preserves that public shape
  and still gives local standard-domain resolution enough information to
  distinguish exact case variants.

3. Keep exact-first, unique-only fallback resolution.

- Trace: `fvk/FINDINGS.md` F-003.
- Obligations: PO-005, PO-006, PO-008.
- Decision: `_resolve_term()` first checks the exact key, then falls back to a
  case-insensitive match only when all folded matches point to one
  `(docname, labelid)`.
- Reason: exact matching is required to make `MySQL` and `mysql` usable as
  distinct terms. The fallback preserves historical and i18n behavior only when
  it cannot select the wrong target.

4. Keep the `:any:` resolver change from V1.

- Trace: `fvk/FINDINGS.md` F-003.
- Obligation: PO-007.
- Decision: `resolve_any_xref()` continues to delegate term lookup to
  `_resolve_term(target)` instead of constructing a lowercased object key.
- Reason: otherwise `:any:` would still reintroduce the lowercase collision for
  standard-domain term objects.

5. No test files were changed and no commands were run.

- Trace: `fvk/FINDINGS.md` F-004.
- Obligation/process note: all proof obligations are constructed, not
  machine-checked.
- Decision: no tests, Python, or K tooling were executed, and no test files were
  modified.
- Reason: the task forbids execution and test-file edits. The emitted K
  commands and test recommendations are for a future valid environment.

## Artifact Decisions

The task required five files under `fvk/`: `SPEC.md`, `FINDINGS.md`,
`PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`. The FVK
documentation also marks the formal core and adequacy audits as non-optional, so
I additionally wrote `mini-sphinx-glossary.k`, `sphinx-glossary-spec.k`,
`INTENT_SPEC.md`, `PUBLIC_EVIDENCE_LEDGER.md`, `FORMAL_SPEC_ENGLISH.md`,
`SPEC_AUDIT.md`, and `PUBLIC_COMPATIBILITY_AUDIT.md`.
