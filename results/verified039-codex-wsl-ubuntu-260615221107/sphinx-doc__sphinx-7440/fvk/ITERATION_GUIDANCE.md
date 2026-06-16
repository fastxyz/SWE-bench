# Iteration Guidance

Status: V2 source has been revised based on FVK findings.

## Code Decision

V1 did not stand unchanged. Finding F-002 showed that V1 changed the public
pending-xref target shape for `:term:` references by removing lowercasing.

V2 keeps the core V1 fix for F-001: glossary terms are registered by exact
visible spelling. V2 improves the role/resolver path:

- `TermXRefRole` preserves the historical lowercased `reftarget`.
- `TermXRefRole` stores the normalized original target in `std:term-original`.
- `_resolve_obj_xref()` uses `std:term-original` for local exact term lookup.
- `_resolve_term()` remains exact-first with an unambiguous folded fallback.

## Recommended Tests To Add Externally

Do not edit tests in this benchmark task. In a normal development pass, add or
keep tests for:

- A glossary containing both `MySQL` and `mysql` emits no duplicate warning and
  exposes both terms from `get_objects()`.
- Exact duplicate `mysql` entries still warn.
- A `:term:` reference to `MySQL` creates a pending xref with `reftarget == 'mysql'` and
  `std:term-original == 'MySQL'`.
- With both terms registered, a local `:term:` reference to `MySQL` resolves to
  the `MySQL` label and one to `mysql` resolves to the `mysql` label.
- A non-exact `:term:` reference to `MYSQL` with both terms registered does not
  resolve to an arbitrary local target.
- Existing i18n glossary-term tests continue not to warn `term not in glossary`.
- Intersphinx can still resolve a lowercased external `std:term` inventory key.

## Open Work

Run the emitted K commands and the Sphinx test suite in an environment where
execution is allowed. Until then, this proof remains constructed, not
machine-checked.
