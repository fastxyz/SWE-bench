# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public symbols

None.

## Changed private/internal symbols

`Query.get_aggregation()` internal control flow now tracks `refs_window` and
includes it in the existing wrapper condition.

## Signature compatibility

`Query.get_aggregation(self, using, aggregate_exprs)` is unchanged.

## Return shape compatibility

The method still returns a dictionary mapping aggregate aliases to aggregate
results. V1 changes only the SQL query shape selected for an existing valid
query pattern.

## Callsite and override compatibility

No new parameters, callbacks, virtual dispatch arguments, or override contracts
were introduced.

## Producer/consumer compatibility

The wrapper path already produces an `AggregateQuery` over an inner query. V1
only routes selected-window-annotation aggregate cases to that existing producer
shape. The outer aggregate annotations and result conversion path are unchanged.

Verdict: compatible.
