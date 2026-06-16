# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims

The formal claims are in `sphinx-glossary-spec.k` over the abstract semantics in
`mini-sphinx-glossary.k`.

Required future machine-check commands:

```sh
cd fvk
kompile mini-sphinx-glossary.k --backend haskell
kast --backend haskell sphinx-glossary-spec.k
kprove sphinx-glossary-spec.k
```

Expected machine-check result, if the abstract semantics and claims parse as
written: `#Top`.

## Proof Sketch

PO-001 and PO-003:

`make_glossary_term()` computes `termtext = term.astext()` and calls
`std.note_object('term', termtext, node_id, location=term)`. The duplicate
predicate in `note_object()` is exact membership of `(objtype, name)` in
`self.objects`. For two inputs `MySQL` and `mysql`, the keys are
`('term', 'MySQL')` and `('term', 'mysql')`, which are unequal Python strings.
Therefore the second registration does not take the duplicate-warning branch,
and both keys can remain in `self.objects`.

PO-002:

For two exact `mysql` registrations, the second call checks the same exact key
`('term', 'mysql')` already inserted by the first. The existing warning branch
in `note_object()` is unchanged, so the exact duplicate warning remains.

PO-004:

`TermXRefRole.process_link()` first invokes the base `XRefRole.process_link()`,
which performs the existing whitespace normalization. It then stores that
normalized original target in `refnode['std:term-original']` and returns
`target.lower()` as the role target. The final `pending_xref['reftarget']`
therefore remains lowercased as before V1, while the original spelling remains
available to `StandardDomain.resolve_xref()`.

PO-005:

`_resolve_obj_xref()` uses `node.get('std:term-original', target)` for
`typ == 'term'`. For a local `:term:` reference to `MySQL`, this value is
`MySQL`; `_resolve_term('MySQL')` checks exact membership first and returns the
`MySQL` target before considering folded compatibility matches. This discharges
exact local resolution when both `MySQL` and `mysql` exist.

PO-006:

If `_resolve_term(T)` has no exact key, it builds a set of all labels whose term
names have `name.lower() == T.lower()`. If the set has one element, every
case-folded match denotes the same target, so returning it preserves historical
case-insensitive behavior without changing the resolved destination. If the set
has zero elements, there is no target. If it has more than one element, at least
two distinct targets share the folded name; returning no local target avoids an
arbitrary choice.

PO-007:

`resolve_any_xref()` no longer rewrites term lookup to `(term, target.lower())`.
It delegates to `_resolve_term(target)`, so exact `:any:` targets and
unambiguous case-insensitive fallback follow the same proof as PO-005 and
PO-006.

PO-008:

The i18n transform calls `make_glossary_term()` for translated `nodes.term`
content using the existing node id. The exact translated term text becomes an
object key. Translated `:term:` references produced by `TermXRefRole` retain the
translated original target in `std:term-original`; exact translated lookup
therefore succeeds. If translation changes only case, exact lookup may miss but
the original and translated entries share the same `(docname, labelid)`, so the
set-based fallback has size one and resolves.

## Residual Risk

This is a partial-correctness proof over a deliberately small abstract model.
It does not prove Sphinx build termination, full docutils parser behavior, or
all intersphinx behavior. It also has not been machine-checked.

## Test Guidance

Do not remove tests based on this constructed proof. After machine-checking,
unit tests that only assert the in-domain claims above may be redundant, but
integration tests for parsing, i18n, inventory, and intersphinx should remain.
