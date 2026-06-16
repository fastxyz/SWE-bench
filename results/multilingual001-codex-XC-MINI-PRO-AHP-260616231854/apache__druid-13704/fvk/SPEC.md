# FVK Specification: Arithmetic post-aggregator `pow`

Status: constructed, not machine-checked.

## Scope

This FVK pass audits the V1 production change in `repo/processing/src/main/java/org/apache/druid/query/aggregation/post/ArithmeticPostAggregator.java`. The audited observable is native arithmetic post-aggregator behavior for function name `pow`, including constructor recognition, computation, null propagation, left-to-right field folding, and cache-key field-order handling.

The proof model is intentionally minimal. It models only the arithmetic operation dispatch and compute loop needed by the issue. Java `Math.pow` itself is treated as a trusted JDK/library primitive represented by `mathPow` in the K model.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | "Support Post aggregation function pow(f1,f2)" | Native arithmetic post-aggregator must accept `fn = "pow"` for at least two numeric fields. | Encoded in `PO-1`, K claim `LOOKUP-POW`. |
| I2 | prompt | "equivalent to Math.pow()" | `pow(lhs, rhs)` computes exactly Java `Math.pow(lhs, rhs)` over double values. | Encoded in `PO-2`, K claim `POW-PAIR`. |
| I3 | prompt | "Square ... pow(f1,2) ... Cube ... power(f1,3) ... Squar root ... power(f1,0.5)" | Integer and fractional exponent constants are valid numeric operands; the feature supports square, cube, and square-root use cases through the exponent. | Encoded as examples under the same `Math.pow` postcondition. |
| I4 | docs | Arithmetic post-aggregator "applies the provided function to the given fields from left to right." | For more than two fields, `pow` follows the existing left-to-right arithmetic fold rather than enforcing binary-only arity. | Encoded in `PO-3`, K claim `POW-FOLD-THREE`. |
| I5 | source contract | Constructor requires `fields != null && fields.size() > 1`. | The in-domain field list contains at least two post-aggregators. | Encoded as a precondition; unchanged from existing arithmetic post-aggregator behavior. |
| I6 | source comment | `compute` returns `null` if any field computes to `null`. | Existing null propagation applies to `pow` as to the other arithmetic operations. | Encoded in `PO-4`, K claim `POW-NULL`. |
| I7 | cache correctness | `pow(a,b)` and `pow(b,a)` are generally different. | Cache keys for `pow` must preserve field order. | Encoded in `PO-5`, K claim `POW-CACHE-ORDER`. |
| I8 | public docs/source | Expression docs define `pow(x, y)` and SQL `POWER` converts to expression function `"pow"`. | The native function spelling is `pow`; the prompt's later word `power` is not enough to require a new `power` alias. | Recorded in Finding FVK-3; no source change. |

## Intended Contract

For an arithmetic post-aggregator with `fnName = "pow"` and `fields = [f0, f1, ..., fn]` where `n >= 1`:

1. Construction succeeds by resolving `Ops.lookup("pow")` to the `POW` operation.
2. If any `fi.compute(values)` returns `null`, `compute(values)` returns `null`.
3. Otherwise each field result is cast to `Number` and converted with `doubleValue()`.
4. The result is the existing arithmetic left fold using Java `Math.pow`:
   - two fields: `Math.pow(d0, d1)`;
   - three fields: `Math.pow(Math.pow(d0, d1), d2)`;
   - generally: `foldPow([d0, ..., dn])`.
5. The output type remains `ColumnType.DOUBLE`.
6. The cache key includes the function name and preserves the field cache-key order for `pow`.

## Source Mapping

- Constructor dispatch: `ArithmeticPostAggregator.java:84-87`.
- Compute loop and null propagation: `ArithmeticPostAggregator.java:110-130`.
- Cache-key branch: `ArithmeticPostAggregator.java:153-164` and `198-211`.
- V1 `POW` enum implementation: `ArithmeticPostAggregator.java:251-256`.
- Lookup map population: `ArithmeticPostAggregator.java:259-264`.

## Adequacy Result

The formal English paraphrases in `fvk/FORMAL_SPEC_ENGLISH.md` match the intent entries above. The only ambiguous wording is the prompt's later use of "power"; public Druid expression naming and the issue title resolve the native post-aggregator function name to `pow`.
