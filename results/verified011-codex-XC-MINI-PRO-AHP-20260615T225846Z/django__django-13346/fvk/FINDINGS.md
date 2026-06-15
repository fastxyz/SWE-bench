# FVK Findings

Status: constructed from public intent and source inspection, not machine-checked.

## F1 - V1 did not satisfy Oracle large-list splitting

Classification: code bug in V1, fixed in V2.

Input: Oracle JSON key-transform lookup with a direct literal `__in` list longer than `connection.ops.max_in_list_size()` after V1 RHS adaptation.

Observed in V1 by source reasoning: `KeyTransformIn.resolve_expression_parameter()` inlined every Oracle RHS literal as `JSON_VALUE(...)` or `JSON_QUERY(...)` and returned no RHS params. Generic `In.split_parameter_list_as_sql()` then iterated `range(0, len(rhs_params), max_in_list_size)`, so `len(rhs_params) == 0` produced no `IN` chunks.

Expected: large `IN` lists preserve Django's generic split behavior by producing chunks that cover every RHS value.

Proof obligations: PO6 and PO7.

Resolution: V2 adds an Oracle-specific `split_parameter_list_as_sql()` branch for the zero-RHS-param case, chunking by RHS SQL fragment count and repeating LHS params per chunk.

## F2 - V1 did not prove Oracle string literals for all strings

Classification: code bug in V1, fixed in V2.

Input: Oracle JSON key-transform `__in` string value containing a SQL single quote, e.g. a JSON string value with an apostrophe.

Observed in V1 by source reasoning: the Oracle RHS helper constructed a SQL string literal directly from `json.dumps({'value': value})`. A single quote inside the JSON string was not escaped for the surrounding SQL literal.

Expected: Oracle strings are explicitly in scope, and string literal construction must remain valid for the whole string family.

Proof obligations: PO4 and PO5.

Resolution: V2 adds `_json_value_literal()` and uses it from both `KeyTransformExact` and `KeyTransformIn`, doubling SQL single quotes after JSON serialization.

## F3 - JSON null in `__in` remains generic `In` behavior

Classification: intentional frame condition, not a code bug for this issue.

Input: `value__key__in=[None]`.

Observed by source reasoning: generic `In.process_rhs()` removes `None` before RHS adaptation.

Expected for this audit: unchanged. The public issue compares direct scalar key values and explicitly identifies numeric single-element lists and Oracle strings. It does not require changing generic SQL `NULL` semantics for `IN`.

Proof obligations: PO7.

Resolution: no code change.

## F4 - Proof is constructed, not machine-checked

Classification: proof status caveat.

Input: all proof obligations.

Observed: task instructions forbid running K tooling, tests, Python, or other execution.

Expected: artifacts contain exact commands and label the proof as constructed, not machine-checked.

Proof obligations: PO8.

Resolution: commands are recorded in `SPEC.md` and `PROOF.md`; no execution was attempted.
