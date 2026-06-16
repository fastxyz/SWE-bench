# FVK Specification

Status: constructed from public intent and source inspection; not machine-checked.

## Scope

The audited production unit is
`repo/lucene/queryparser/src/java/org/apache/lucene/queryparser/classic/MultiFieldQueryParser.java`,
specifically the quoted-term path `getFieldQuery(String field, String queryText, int slop)` and its
private helper `applySlop(Query q, int slop)`.

The observable behavior under audit is the query tree produced for quoted multi-field input when a
per-field boost is configured. The user-visible symptom is the rendered query string, but the
property being specified is structural: the output query must contain both the parsed phrase slop and
the configured field boost.

## Public Intent Ledger

I-001, source `benchmark/PROBLEM.md`: "Output is field1:\"hello world\"~1^1.5".
Semantic obligation: for a boosted phrase query parsed with explicit slop `1`, both slop `1` and
boost `1.5` must be present in the resulting query.
Status: encoded in SPEC-C-003 and PO-003/PO-005.

I-002, source `benchmark/PROBLEM.md`: "the slop is missing from output".
Semantic obligation: preserving the boost while leaving the inner phrase at its old/default slop is
the bug, not acceptable legacy behavior.
Status: encoded as Finding F-001.

I-003, source `benchmark/PROBLEM.md` public hint: "`setBoost()` function was replaced with
`new BoostQuery()`, but BoostQuery is not handled in setSlop function."
Semantic obligation: the slop-setting helper must treat `BoostQuery` as a transparent wrapper for
the slop operation while preserving the wrapper's boost.
Status: encoded in SPEC-C-004 and PO-003.

I-004, source code: `applySlop` already rebuilds `PhraseQuery` and `MultiPhraseQuery` with the
requested slop and leaves other query types unchanged.
Semantic obligation: the fix should preserve this existing behavior and extend it only through
boost-wrapper transparency.
Status: encoded in SPEC-C-001, SPEC-C-002, SPEC-C-005, and PO-001/PO-002/PO-006.

I-005, source code: `getFieldQuery(..., int slop)` applies configured field boosts before calling
`applySlop` in the `field == null` multi-field path.
Semantic obligation: the helper must be correct when its input is already a `BoostQuery`.
Status: encoded in PO-005.

I-006, compatibility evidence: V1 changes only a private helper body and does not alter public
constructors, method signatures, return types, or test files.
Semantic obligation: no public API or override compatibility migration is required.
Status: encoded in PO-008.

## Abstract Query Model

The formal model in `fvk/mini-queryparser.k` abstracts only the query structure relevant to the
defect:

- `phrase(payload, slop)` models a `PhraseQuery` and keeps phrase content as opaque `payload`.
- `multiPhrase(payload, slop)` models a `MultiPhraseQuery` and keeps phrase content as opaque
  `payload`.
- `boost(query, boost)` models `BoostQuery`, keeping the boost as an opaque value.
- `other(payload)` models non-phrase query types that `applySlop` must leave unchanged.
- `nullQuery` models the helper's null-tolerant behavior through Java `instanceof` checks.

This abstraction is property-complete for the issue because it preserves the exact axes the defect
manipulates and the user observes: phrase slop, boost wrapper, and query payload preservation.

## Contracts

SPEC-C-001, direct phrase: `applySlop(phrase(P, OLD), S) = phrase(P, S)`.

SPEC-C-002, direct multi-phrase: `applySlop(multiPhrase(P, OLD), S) = multiPhrase(P, S)`.

SPEC-C-003, boosted phrase: `applySlop(boost(phrase(P, OLD), B), S) = boost(phrase(P, S), B)`.

SPEC-C-004, boosted multi-phrase: `applySlop(boost(multiPhrase(P, OLD), B), S) =
boost(multiPhrase(P, S), B)`.

SPEC-C-005, frame for non-phrase and null queries: `applySlop` returns non-phrase and null inputs
unchanged, including when the non-phrase query is wrapped in `boost`.

SPEC-C-006, parser composition: in the multi-field quoted path, if `super.getFieldQuery` produces a
phrase-like query `Q` for field `F` and `boosts.get(F) = B`, the result after the V1 helper is
`boost(applySlop(Q, S), B)`, not `applySlop(Q, S)` without boost and not `boost(Q, B)` without slop.

## Adequacy And Compatibility

The formal English obligations above are entailed by public issue text and the public hint, not by
the candidate implementation alone. The legacy output without slop is marked suspect because the
issue identifies it as the bug.

Public compatibility audit: no public symbol or dispatch signature changed. `applySlop` is private,
and the public constructors and protected parser methods keep their signatures. No test files were
modified.
