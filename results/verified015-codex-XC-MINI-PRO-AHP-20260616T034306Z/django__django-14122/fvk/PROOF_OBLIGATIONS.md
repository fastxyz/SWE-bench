# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Metadata ordering excluded for grouped queries

For every grouped query with no `extra_order_by`, no explicit `query.order_by`,
default ordering enabled, and model `Meta.ordering` present, `get_order_by()`
must not select metadata ordering.

Discharged by:

- source edit in `repo/django/db/models/sql/compiler.py`;
- claim `GROUPED-META-SUPPRESSED`.

## PO-2: No downstream metadata bypass through hidden selects or grouping

Because `pre_sql_setup()` passes the selected ordering to both
`get_extra_select()` and `get_group_by()`, metadata ordering must be absent from
the selected ordering before both calls.

Discharged by:

- same source edit in `SQLCompiler.get_order_by()`;
- `GROUPED-META-SUPPRESSED`, whose result has `orderByHasMeta == false`,
  `extraSelectHasMeta == false`, and `groupByHasMeta == false` for all distinct
  flag values.

## PO-3: Non-grouped metadata ordering preserved

The fix must not remove default metadata ordering from ordinary non-grouped
queries.

Discharged by:

- guarded condition `self.query.group_by is None`;
- claim `UNGROUPED-META-PRESERVED`.

## PO-4: Explicit and extra ordering preserved

The fix must not remove user-specified ordering from grouped queries.

Discharged by:

- existing precedence branches for `extra_order_by` and `query.order_by`, which
  run before the metadata-ordering branch;
- claims `GROUPED-EXPLICIT-PRESERVED` and `GROUPED-EXTRA-PRESERVED`.

## PO-5: Public `ordered` introspection uses the same grouped sentinel

`QuerySet.ordered` must not report default metadata ordering as active for a
query whose `query.group_by` is a grouped state. The no-grouping sentinel is
`None`, not falsiness.

Discharged by:

- source edit in `repo/django/db/models/query.py`;
- `GROUPED-META-SUPPRESSED` and `UNGROUPED-META-PRESERVED`, whose
  `orderedProperty` component differs exactly on `grouped` vs `noGroup`.

## PO-6: Honesty and compatibility obligations

The proof must remain labeled "constructed, not machine-checked"; no tests or
formal tools were run. Public signatures, return shapes, and explicit ordering
behavior must remain compatible.

Discharged by:

- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`;
- exact commands listed in `fvk/PROOF.md`;
- no test-file edits.
