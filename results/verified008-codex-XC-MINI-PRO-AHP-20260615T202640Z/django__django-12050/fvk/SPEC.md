# SPEC

Status: constructed, not machine-checked.

## Target

Target unit: `Query.resolve_lookup_value()` in
`repo/django/db/models/sql/query.py`.

Call path under audit: `Query.build_filter()` calls
`resolve_lookup_value()` before `build_lookup()`, so the value returned by
`resolve_lookup_value()` is the right-hand side received by lookup classes and
field preparation.

## Intent-Only Spec

The public issue says:

- "Query.resolve_lookup_value coerces value of type list to tuple"
- "input value list to be coerced to tuple breaking exact value queries"
- "This affects ORM field types that are dependent on matching input types such
  as PickledField"
- "The expected iterable return type should match input iterable type."

Required behavior derived from that public intent:

1. A top-level lookup value that is a Python `list` remains a `list` after
   expression resolution.
2. A top-level lookup value that is a Python `tuple` remains a `tuple` after
   expression resolution.
3. Elements of a top-level list or tuple are still resolved independently when
   they expose `resolve_expression()`.
4. Element order and length are preserved.
5. Non-expression, non-list, non-tuple values are not changed by this method.
6. A top-level expression value is still resolved using the existing expression
   path.

The public intent does not independently specify exact concrete subclass
preservation for `list` or `tuple` subclasses. That question is recorded as an
ambiguity in `FINDINGS.md` and is not used to justify a broader source edit.

## Public Evidence Ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "coerces value of type list to tuple" | A list input must not become a tuple. | Encoded by PO-1 and K claim `LIST-PRESERVES-CONSTRUCTOR`. |
| E2 | prompt | "breaking exact value queries" | The type-preserved value must reach exact lookup field preparation. | Encoded by PO-5. |
| E3 | prompt | "field types that are dependent on matching input types such as PickledField" | Top-level RHS type is semantically observable and cannot be treated as an implementation detail. | Encoded by PO-1 and PO-5. |
| E4 | prompt | "expected iterable return type should match input iterable type" | The supported iterable categories handled by this method, list and tuple, must be reconstructed with the same category. | Encoded by PO-1 and PO-2. |
| E5 | source | Comment: "The items of the iterable may be expressions and therefore need to be resolved independently." | Element-wise expression resolution must remain intact. | Encoded by PO-3. |
| E6 | source | `build_filter()` passes `value = self.resolve_lookup_value(...)` into lookup building. | No later top-level repair point exists before lookup construction. | Encoded by PO-5. |
| E7 | source | No other call sites or overrides of `resolve_lookup_value()` were found in `repo/django` or `repo/tests`. | Compatibility risk is limited to return-shape behavior, not signature or dispatch changes. | Encoded by PO-6. |
| E8 | baseline notes | V1 deliberately preserves list vs tuple but not exact subclasses. | Subclass preservation needs a separate public-intent basis. | Finding F-003. |

## Formal Model

The mini-K model abstracts Python values into:

- `atom(X)` for values without `resolve_expression()` that are not top-level
  list or tuple values.
- `expr(X)` for non-`F` expression values.
- `fexpr(X)` for `F` expressions, because the implementation passes
  `simple_col` only for this expression class.
- `pyList(VS)` and `pyTuple(VS)` for the two supported iterable categories.

The model intentionally treats expression resolution as an uninterpreted
constructor:

- `expr(X)` resolves to `resolved(X, can_reuse, allow_joins)`.
- `fexpr(X)` resolves to
  `fresolved(X, can_reuse, allow_joins, simple_col)`.

This is sufficient for the issue because the defect is not the internals of
expression resolution; it is the top-level iterable constructor used after
element resolution.

The K artifacts are:

- `fvk/mini-python-resolve-lookup.k`
- `fvk/resolve-lookup-value-spec.k`

## Formal Spec English

Claim `LIST-PRESERVES-CONSTRUCTOR`:

For every abstract value sequence `VS` and flags `CR`, `AJ`, and `SC`,
resolving `pyList(VS)` returns `pyList(resolveLookupValues(VS, CR, AJ, SC))`.
The result constructor is a list constructor.

Claim `TUPLE-PRESERVES-CONSTRUCTOR`:

For every abstract value sequence `VS` and flags `CR`, `AJ`, and `SC`,
resolving `pyTuple(VS)` returns `pyTuple(resolveLookupValues(VS, CR, AJ, SC))`.
The result constructor is a tuple constructor.

Claim `ELEMENTS-RESOLVE-IN-ORDER`:

Resolving a non-empty value sequence resolves the head with the same flags,
then recursively resolves the tail. This preserves element order and length.

Claim `EXPR-RESOLUTION-FRAME`:

Top-level `expr(X)` and `fexpr(X)` values are resolved with the same flag
choices as the source code uses. `fexpr(X)` receives the `simple_col` flag;
ordinary `expr(X)` does not.

Claim `ATOM-FRAME`:

An `atom(X)` value is returned unchanged.

Integration obligation `EXACT-RHS-FLOW`:

`build_filter()` passes the return value from `resolve_lookup_value()` into
lookup construction. Therefore preserving the top-level list constructor in
`resolve_lookup_value()` is sufficient for exact lookup field preparation to
receive a list instead of a tuple.

## Spec Audit

| Formal entry | Intent match | Result |
| --- | --- | --- |
| `LIST-PRESERVES-CONSTRUCTOR` | Directly matches E1, E3, and E4. | Pass |
| `TUPLE-PRESERVES-CONSTRUCTOR` | Directly matches E4 and preserves pre-existing tuple behavior. | Pass |
| `ELEMENTS-RESOLVE-IN-ORDER` | Matches source comment E5 and preserves the purpose of the method branch. | Pass |
| `EXPR-RESOLUTION-FRAME` | Matches the existing source behavior outside the bug; no prompt evidence asks to change expression resolution. | Pass |
| `ATOM-FRAME` | Matches existing frame behavior outside the bug; no prompt evidence asks to change atom values. | Pass |
| Exact subclass preservation | Not independently specified by the prompt, tests read, or source comments. | Ambiguous, recorded as F-003 |

## Public Compatibility Audit

Changed public symbol: none. V1 changes only the reconstruction expression inside
`Query.resolve_lookup_value()`.

Signature compatibility:

- `resolve_lookup_value(self, value, can_reuse, allow_joins, simple_col)` is
  unchanged.

Callsite compatibility:

- The only source call site found is `Query.build_filter()`.
- No overrides of `resolve_lookup_value()` were found in `repo/django` or
  `repo/tests`.

Return-shape compatibility:

- Built-in list inputs now return lists, as required by the public issue.
- Tuple inputs still return tuples.
- Non-list, non-tuple, and top-level expression paths are unchanged.
- Exact subclass preservation remains under-specified and is not claimed.

