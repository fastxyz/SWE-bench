# Formal Spec English

Status: constructed, not machine-checked.

## GROUPED-META-SUPPRESSED

For every value of `distinct` and `distinct_fields`, if a query has no
`extra_order_by`, no explicit `query.order_by`, default ordering is enabled,
the model has `Meta.ordering`, and grouping is active, compilation chooses no
ordering source. Metadata ordering does not appear in the selected `ORDER BY`
input, in hidden distinct selects, or in `GROUP BY`. `QuerySet.ordered` is false
for this default-ordering-only grouped state.

## UNGROUPED-META-PRESERVED

For every value of `distinct` and `distinct_fields`, if the same query is not
grouped, compilation chooses metadata ordering. Hidden distinct selects may use
the metadata ordering exactly when `distinct` is true and `distinct_fields` is
false. `QuerySet.ordered` is true for this ordinary default-ordered query.

## GROUPED-EXPLICIT-PRESERVED

For every default-ordering flag, metadata-ordering flag, and distinct state, if
a grouped query has explicit `query.order_by`, compilation chooses explicit
ordering and the query is ordered. The ordering is not metadata-derived.

## GROUPED-EXTRA-PRESERVED

For every default-ordering flag, explicit-ordering flag, metadata-ordering flag,
and distinct state, if a grouped query has `extra_order_by`, compilation chooses
extra ordering and the query is ordered. The ordering is not metadata-derived.
