# Public Evidence Ledger

E-001

- Source: prompt
- Quote: `Warning, treated as error: ... duplicate term description of mysql`
- Semantic obligation: the reported duplicate warning is the defect.
- Status: encoded in `SPEC.md` and K claim `CASE-DISTINCT-REGISTRATION`.

E-002

- Source: prompt
- Quote: `MySQL != mysql term right ?`
- Semantic obligation: term identity for glossary registration is
  case-sensitive.
- Status: encoded in `SPEC.md` and K claims for exact registration and exact
  term resolution.

E-003

- Source: public-test
- Quote: `duplicated terms` with two `term-case4` entries expects
  `duplicate term description of term-case4`.
- Semantic obligation: exact duplicates still warn.
- Status: encoded in `SPEC.md` and K claim `EXACT-DUPLICATE-WARNS`.

E-004

- Source: implementation/public compatibility
- Quote: base standard-domain `roles` used
  `XRefRole(lowercase=True, innernodeclass=nodes.inline, warn_dangling=True)`
  for `term`; `intersphinx.missing_reference()` uses
  `node['reftarget']` directly for inventory lookup.
- Semantic obligation: preserve the lowercased public `reftarget` shape unless
  public intent requires changing it.
- Status: V1 violated this compatibility condition; V2 fixes it with
  `TermXRefRole`.

E-005

- Source: public-test/i18n
- Quote: `assert 'term not in glossary' not in warnings` for translated
  glossary terms.
- Semantic obligation: unambiguous translated/case-changed term references
  should still resolve.
- Status: encoded in `_resolve_term()`'s unique-target fallback.

E-006

- Source: implementation/public API
- Quote: `StandardDomain.get_objects()` yields the `objects` map for inventory
  and search consumers.
- Semantic obligation: both `MySQL` and `mysql` must be representable as
  separate public term objects.
- Status: encoded by registering `termtext`, not `termtext.lower()`.
