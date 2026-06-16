# FVK Findings

Status: constructed, not machine-checked.

## F1 - Resolved code bug: aggregate over selected window annotation used direct SQL shape

Classification: code bug, resolved by V1.

Input shape:

```python
queryset.annotate(
    cumul_DJR=Coalesce(Window(Sum("DJR"), order_by=F("date").asc()), 0.0)
).aggregate(
    DJR_total=Sum("DJR"),
    cumul_DJR_total=Sum("cumul_DJR"),
)
```

Observed in V0:

`Sum("cumul_DJR")` resolved to a `Ref` to the annotation, but the direct
aggregation path then replaced that `Ref` with the annotation expression. The
resulting SQL shape placed an aggregate call directly around a window function,
which PostgreSQL rejects.

Expected:

The query must be wrapped so the inner query selects `cumul_DJR` and the outer
aggregate compiles as an aggregate over that selected alias.

Evidence:

- Intent ledger I1, I2, I3, I4.
- `Ref.as_sql()` emits the alias name (`repo/django/db/models/expressions.py:1206`).
- V1 computes `refs_window` from aggregate refs and includes it in the wrapper
  condition (`repo/django/db/models/sql/query.py:419-460`).

Proof obligations:

PO1, PO2, PO3.

Decision:

No additional code change required. V1 discharges this finding.

## F2 - Ambiguous extension: direct `Aggregate(Window(...))`

Classification: underspecified intent / possible future feature.

Input shape:

```python
queryset.aggregate(total=Sum(Window(Sum("DJR"), order_by=F("date").asc())))
```

Observed in audit:

V1 does not attempt to support this direct nesting. Simply forcing the existing
aggregate wrapper for every expression with `contains_over_clause` would not be
enough, because the current wrapper logic preserves selected annotation `Ref`s
and repoints raw columns; it does not hoist arbitrary window-containing
expression trees into the inner query.

Expected:

No expectation is fixed by the available public evidence. The issue example and
Django docs evidence are annotation-based.

Evidence:

- Intent ledger I2, I3, I4.
- Baseline notes already identified this as an alternative interpretation.

Proof obligations:

PO6.

Decision:

Do not broaden V1 without clearer public intent. If this is intended public API,
the next iteration should implement expression lifting for direct window
subexpressions and add focused tests.

## F3 - Proof capability and execution boundary

Classification: proof capability gap.

The FVK proof here is constructed over a mini model of the wrapping decision and
SQL shape. It is not machine-checked, and no Django tests, Python code, or K
tooling were executed, per task constraints.

Decision:

Keep Django's public tests. Any test-redundancy recommendation is conditional on
running the emitted K commands and the Django test suite in a real execution
environment.
