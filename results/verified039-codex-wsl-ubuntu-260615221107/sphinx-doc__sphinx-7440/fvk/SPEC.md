# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tools were run.

## Scope

Audited source: `repo/sphinx/domains/std.py`.

Formalized units:

- `make_glossary_term()` term object registration.
- `TermXRefRole.process_link()` pending-reference target construction.
- `StandardDomain._resolve_term()` term lookup.
- `StandardDomain._resolve_obj_xref()` for `typ == 'term'`.
- `StandardDomain.resolve_any_xref()` for term objects.

The mini-K model abstracts Sphinx/Python to the observable state needed for this
issue: a finite term-object map, duplicate-warning events, pending term
reference targets, and term resolution results.

## Public Intent Ledger

See `PUBLIC_EVIDENCE_LEDGER.md` for the standalone ledger. The controlling
entries are:

- E-001/E-002: the reported `MySQL`/`mysql` duplicate warning is a bug; those
  terms are distinct for glossary registration.
- E-003: exact duplicate glossary terms still warn.
- E-004: preserving the lowercased `pending_xref['reftarget']` is a public
  compatibility condition because intersphinx consumes it directly.
- E-005: unambiguous case-insensitive term lookup is preserved for historical
  behavior and i18n.
- E-006: term object names are public through `get_objects()`/inventory/search.

## Contract

Let `Obj` be the standard-domain object map for glossary terms, keyed by exact
visible term text and valued by `(docname, labelid)`.

Registration:

- `register(T, L)` emits a duplicate warning iff `T` is already an exact key in
  `Obj`.
- `register(T, L)` updates `Obj[T] = L`.
- Therefore `register("MySQL", L1); register("mysql", L2)` emits no duplicate
  warning and leaves both exact keys present.

Term role parsing:

- `:term:` target text is normalized for whitespace.
- The public `pending_xref['reftarget']` remains the lowercased normalized
  target, matching the previous role behavior.
- The normalized original spelling is stored as `pending_xref['std:term-original']`
  for local standard-domain resolution.

Term resolution:

- Local `std:term` resolution uses `std:term-original` when present, otherwise
  `reftarget` for old doctrees.
- `_resolve_term(T)` first returns an exact `Obj[T]` match.
- If there is no exact match, `_resolve_term(T)` collects all term labels whose
  names lower-case to `T.lower()`.
- If that set of labels has exactly one member, the unique label is returned.
- Otherwise no local term target is returned; the resolver must not choose among
  distinct case variants.

`:any:` term resolution:

- `resolve_any_xref()` uses `_resolve_term(target)` for standard-domain terms,
  so exact `:any:` targets can find exact-case glossary entries and ambiguous
  case-folded targets do not guess.

## Adequacy

The formal English paraphrase in `FORMAL_SPEC_ENGLISH.md` matches the intent
spec in `INTENT_SPEC.md`; see `SPEC_AUDIT.md`.

## Machine-Check Commands

These commands are emitted for a future environment with K installed. They were
not run here.

```sh
cd fvk
kompile mini-sphinx-glossary.k --backend haskell
kast --backend haskell sphinx-glossary-spec.k
kprove sphinx-glossary-spec.k
```
