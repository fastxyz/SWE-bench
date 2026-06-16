# Public Compatibility Audit

Status: constructed by source inspection; no code was executed.

Changed public or semi-public surface:

1. Glossary term object names in `StandardDomain.objects`

- Before the bug fix: glossary terms were stored under `termtext.lower()`.
- Required by issue intent: case-distinct terms must not collide.
- Compatibility result: public inventories/search may now expose original-case
  term names for original-case terms. This is the intended public behavior for
  distinguishing `MySQL` and `mysql`.

2. `std:term` pending reference shape

- V1 changed `pending_xref['reftarget']` from lowercased to original-case.
- Public consumer risk: `sphinx.ext.intersphinx.missing_reference()` uses
  `node['reftarget']` directly for inventory lookup, so old lowercased
  inventories could become harder to resolve.
- V2 result: `TermXRefRole` preserves lowercased `reftarget` and adds
  `std:term-original` for local exact resolution. This handles the issue
  without changing the public `reftarget` shape.

3. `StandardDomain.resolve_xref()` term branch

- The signature is unchanged.
- The term branch reads the optional `std:term-original` attribute when present;
  old doctrees without it still resolve through the lowercased `reftarget`.

4. `StandardDomain.resolve_any_xref()` term branch

- The signature is unchanged.
- The term branch uses `_resolve_term()` directly on the `:any:` target, which
  was not historically lowercased by `AnyXRefRole`.

No public test files or public callsites require edits. Hidden tests and
external benchmark data were not used.
