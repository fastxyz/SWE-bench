# FVK Findings

Status: constructed, not machine-checked.

## FVK-1: Missing `pow` operation before V1

- Classification: code bug, resolved by V1.
- Evidence: prompt requests native post aggregation function `pow(f1,f2)` equivalent to `Math.pow()`.
- Concrete input: arithmetic post-aggregator JSON/source construction with `fn = "pow"` and two numeric fields, for example values `2.0` and `3.0`.
- Pre-V1 observed behavior: `Ops.lookup("pow")` returned `null`, causing constructor error `Unknown operation[pow]`.
- Expected behavior: constructor accepts `pow`, and `compute` returns `Math.pow(2.0, 3.0)`.
- V1 status: resolved by adding `POW("pow")` to `Ops`; the static lookup map includes every enum value.
- Traced proof obligations: `PO-1`, `PO-2`, `PO-3`.

## FVK-2: `pow` cache keys must preserve operand order

- Classification: code correctness risk, resolved by V1.
- Evidence: `pow(2, 3)` and `pow(3, 2)` are generally different, while `appendCacheablesIgnoringOrder` intentionally sorts field cache keys.
- Concrete input: two otherwise identical arithmetic post-aggregators whose fields are swapped.
- Incorrect behavior if omitted: both aggregators could share a cache key even though they compute different values.
- Expected behavior: `pow` follows `-`, `/`, and `quotient` as an order-sensitive operation.
- V1 status: resolved by adding `case POW` to `preserveFieldOrderInCacheKey`.
- Traced proof obligation: `PO-5`.

## FVK-3: `power` alias is not required by public intent

- Classification: underspecified intent, no source change.
- Evidence: the issue title and proposal name `pow`; existing expression docs list `pow(x, y)`; SQL `POWER` converts to expression `"pow"`.
- Ambiguity: the issue body later says `power(f1,3)` and `power(f1,0.5)`.
- Decision: keep the supported native arithmetic function name to `pow` only. Adding `power` would expand public query syntax beyond the concrete requested function and beyond existing Druid expression naming.
- Traced proof obligations: `PO-1`, `PO-7`.

## FVK-4: Multi-field `pow` follows existing arithmetic left fold

- Classification: adequacy check, no source change.
- Evidence: public post-aggregation docs say arithmetic post-aggregators apply the provided function to fields "from left to right"; the constructor accepts any list with more than one field.
- Concrete input: fields `[2.0, 3.0, 2.0]`.
- Expected behavior under existing contract: `Math.pow(Math.pow(2.0, 3.0), 2.0)`.
- Rejected alternative: enforce exactly two fields for `pow`. That would contradict the existing arithmetic post-aggregator arity contract and introduce a special case not requested by public intent.
- Traced proof obligation: `PO-3`.

## FVK-5: Java `Math.pow` is a trusted library primitive in this proof

- Classification: proof capability boundary, not a code bug.
- Evidence: the requested behavior is "equivalent to Math.pow()"; the V1 code delegates directly to `Math.pow(lhs, rhs)`.
- Proof boundary: the mini-K model represents Java `Math.pow` as `mathPow` and proves dispatch to that primitive, not the JDK's floating-point implementation.
- Recommended follow-up: machine-check the K dispatch claims if K is available; rely on JDK correctness for `Math.pow`.
- Traced proof obligation: `PO-2`.

## FVK-6: Documentation remains outside this benchmark repair

- Classification: iteration guidance, no production code change in this pass.
- Evidence: current docs still list supported native arithmetic functions as `+`, `-`, `*`, `/`, and `quotient`.
- Expected product follow-up: update public documentation when landing the feature in a normal development workflow.
- Reason not changed here: the benchmark task asks for source-code repair and explicitly forbids test modifications; the source-code behavior is the repair target.
