# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Direct PhraseQuery slop is set

Claim: for any phrase payload `P`, old slop `OLD`, and requested slop `S`,
`applySlop(phrase(P, OLD), S)` returns `phrase(P, S)`.

Source: SPEC-C-001 and source branch `q instanceof PhraseQuery`.

V1 status: discharged by the pre-existing phrase branch, unchanged by V1.

## PO-002: Direct MultiPhraseQuery slop is set

Claim: for any multi-phrase payload `P`, old slop `OLD`, and requested slop `S`,
`applySlop(multiPhrase(P, OLD), S)` returns `multiPhrase(P, S)`.

Source: SPEC-C-002 and source branch `q instanceof MultiPhraseQuery`.

V1 status: discharged by the pre-existing multi-phrase branch. The Java code rebuilds only when the
slop differs; extensionally this still satisfies the claim.

## PO-003: BoostQuery is transparent to slop and preserves boost

Claim: for any query `Q`, boost `B`, and requested slop `S`,
`applySlop(boost(Q, B), S)` returns `boost(applySlop(Q, S), B)`.

Source: SPEC-C-003, SPEC-C-004, and intent ledger I-003.

V1 status: discharged by the new branch:

```java
if (q instanceof BoostQuery) {
  BoostQuery bq = (BoostQuery) q;
  q = new BoostQuery(applySlop(bq.getQuery(), slop), bq.getBoost());
}
```

## PO-004: Phrase payload is preserved

Claim: applying slop changes only the slop field of phrase-like queries, not their terms, positions,
or other payload.

Source: issue expects the same phrase text with slop added; source code copies terms and positions
when rebuilding `PhraseQuery` and uses `new MultiPhraseQuery.Builder(mpq)` for `MultiPhraseQuery`.

V1 status: discharged by unchanged rebuilding logic and by the boost branch delegating to that logic.

## PO-005: Multi-field parser order composes boost and slop correctly

Claim: in the `field == null` quoted path, if a field boost exists, applying boost before slop still
produces a query with both properties: `boost(applySlop(Q, S), B)`.

Source: intent ledger I-005 and issue reproduction.

V1 status: discharged because `getFieldQuery(..., int slop)` still applies the field boost before
the helper, and PO-003 makes the helper transparent through that wrapper.

## PO-006: Non-phrase and null inputs keep existing behavior

Claim: null and non-phrase inputs are not converted into phrase-like queries and are not assigned
slop by the helper.

Source: SPEC-C-005 and existing helper behavior.

V1 status: discharged. Java `instanceof` is false for `null`, and non-phrase queries reach the final
`return q`. Boosted non-phrase queries are reconstructed as equivalent `BoostQuery` wrappers.

## PO-007: Recursive BoostQuery handling terminates on finite query trees

Claim: recursive descent through `BoostQuery` wrappers terminates for finite query trees.

Source: Java query objects are finite object graphs in this parser path; each recursive call uses
`bq.getQuery()`, removing one outer `BoostQuery` wrapper from the active helper call.

V1 status: discharged for the modeled input domain. Termination is reasoned statically; no execution
was attempted.

## PO-008: Public compatibility is preserved

Claim: the fix must not require public API, constructor, override, or callsite changes.

Source: intent ledger I-006.

V1 status: discharged. The changed method is private, method signatures are unchanged, and no tests
or public APIs were modified.

## PO-009: Formal model distinguishes pass and fail

Claim: the abstraction must distinguish `boost(phrase(P, OLD), B)` from
`boost(phrase(P, S), B)` when `OLD != S`.

Source: FVK property-completeness rule and issue symptom.

V1 status: discharged by representing slop and boost as separate fields in the K query model.

## PO-010: Machine check commands are emitted but not run

Claim: the FVK package must provide commands for later machine checking and label the result
constructed, not machine-checked.

Source: task no-exec instruction and FVK honesty gate.

V1 status: discharged in `PROOF.md` and `ITERATION_GUIDANCE.md`.
