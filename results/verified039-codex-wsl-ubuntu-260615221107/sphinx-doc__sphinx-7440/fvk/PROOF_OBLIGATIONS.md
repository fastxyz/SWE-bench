# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Case-Distinct Registration Does Not Warn

Obligation: registering `MySQL` and `mysql` as glossary terms must use different
object keys and emit no duplicate warning.

Evidence: E-001, E-002.

Discharge: `make_glossary_term()` passes `termtext`, not `termtext.lower()`, to
`std.note_object()`. `StandardDomain.note_object()` checks duplicates by exact
`(objtype, name)` key, so `('term', 'MySQL') != ('term', 'mysql')`.

Linked finding: F-001.

## PO-002: Exact Duplicate Registration Still Warns

Obligation: registering the exact same term text twice still emits the existing
duplicate warning.

Evidence: E-003.

Discharge: unchanged `note_object()` duplicate check still sees the second exact
`('term', name)` key and logs the warning before updating the map.

Linked finding: F-001.

## PO-003: Case-Distinct Terms Are Both Exposed

Obligation: the standard-domain object map can contain both `MySQL` and `mysql`
for inventory/search consumers.

Evidence: E-006.

Discharge: exact registration keys leave both entries in `self.objects`;
`get_objects()` iterates that map unchanged.

Linked finding: F-001.

## PO-004: Term Role Preserves Lowercased Reftarget

Obligation: `:term:` pending references keep the historical lowercased
`reftarget` shape.

Evidence: E-004.

Discharge: `TermXRefRole.process_link()` calls the base whitespace normalizer,
stores the original target in `std:term-original`, and returns `target.lower()`
as the public target.

Linked finding: F-002.

## PO-005: Local Term Resolution Prefers Exact Original Spelling

Obligation: with both `MySQL` and `mysql` registered, a `:term:` reference to
`MySQL` resolves to `MySQL`, not to the lowercased compatibility target.

Evidence: E-002, E-004.

Discharge: `_resolve_obj_xref()` calls `_resolve_term()` with
`node.get('std:term-original', target)`, so local `std:term` resolution sees the
original spelling when the node was produced by `TermXRefRole`.

Linked finding: F-003.

## PO-006: Case-Insensitive Fallback Is Unambiguous Only

Obligation: legacy case-insensitive lookup may resolve only when all
case-folded matches identify the same target.

Evidence: E-005.

Discharge: `_resolve_term()` collects matching `(docname, labelid)` tuples in a
set and returns a target only when `len(matches) == 1`; otherwise it returns no
local target.

Linked finding: F-003.

## PO-007: `:any:` Uses the Same Term Resolver

Obligation: `:any:` lookup for standard-domain terms must not reintroduce the
lowercase collision.

Evidence: E-006.

Discharge: `resolve_any_xref()` delegates term lookup to `_resolve_term(target)`
instead of constructing a lowercased key directly.

Linked finding: F-003.

## PO-008: i18n Translated Terms Remain Resolvable

Obligation: translated glossary terms and translated `:term:` references should
not warn `term not in glossary` when the target is unambiguous.

Evidence: E-005.

Discharge: the i18n transform re-registers translated `nodes.term` text with
the same node id through `make_glossary_term()`. Exact translated references
resolve by exact match; case-only translated differences resolve through the
unique-target fallback because the original and translated spellings point to
the same `(docname, labelid)`.
