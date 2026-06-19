# FVK Findings

Status: constructed, not machine-checked.

## F1: V1 Dropped Subquery Grouping Expressions With External Columns

Classification: code bug in V1, fixed in V2.

Input shape: a non-reference order-by expression whose `get_group_by_cols()`
returns a subquery expression `S` because `S.query.get_external_cols()` contains
possibly multivalued outer-column references, while `S.contains_column_references`
is false and `S.flatten()` contains no `RawSQL`.

Observed in V1: the grouping expression was skipped because V1 only retained
direct `contains_column_references` expressions or expressions containing
`RawSQL`.

Expected from intent: keep the expression. Public intent says column-dependent
ordering must still affect grouping, and `Subquery.get_group_by_cols()` returns
`[self]` specifically when external column grouping cannot be safely reduced to
individual columns.

Resolution: V2 keeps expressions whose flattened sources expose non-empty
`get_external_cols()`.

Trace: `PROOF_OBLIGATIONS.md` PO4 and `django-groupby-spec.k`
`KEEP-EXTERNAL-COLS`.

## F2: Legacy Behavior Added `Random()` To `GROUP BY`

Classification: original code bug, fixed by V1 and preserved by V2.

Input shape: `Thing.objects.annotate(rc=Count('related')).order_by('?').values('id', 'rc')`.

Observed before the fix: `Random()` was returned by `OrderBy(Random()).get_group_by_cols()`
and added to `GROUP BY`, splitting one aggregate row into two rows.

Expected from intent: random ordering must stay in `ORDER BY` only and must not
alter aggregate grouping.

Resolution: V2 skips order-by grouping expressions with no column references,
no raw SQL, and no external columns.

Trace: `PROOF_OBLIGATIONS.md` PO1 and `django-groupby-spec.k` `DROP-RANDOM`.

## F3: No Machine Check Or Runtime Check Was Performed

Classification: proof status and test gap.

The proof is constructed but not machine-checked. Per the task constraints, no
tests, Python, or K tooling were run. The emitted commands in `SPEC.md` and
`PROOF.md` are the commands to run later in an execution-capable environment.

Recommended tests to add in the fixed test suite, without editing tests here:

- aggregation with `order_by('?')` does not include `RANDOM()`/`RAND()` in
  `GROUP BY` and returns one aggregate row;
- aggregation with ordering by a related field still splits groups as before;
- raw SQL ordering remains grouped;
- a non-selected subquery annotation with external columns used for ordering
  remains grouped.
