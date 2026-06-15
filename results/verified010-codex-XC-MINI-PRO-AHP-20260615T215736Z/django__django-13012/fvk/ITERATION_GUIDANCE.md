# FVK Iteration Guidance

Status: V2 source change applied.

## Code Decision

V1 fixed the reported constant-wrapper bug but was incomplete against the full
public compatibility intent. V2 keeps V1's delegation and adds the missing
signature compatibility guard.

No further source edits are recommended after V2.

## Next Tests to Add in a Normal Environment

Do not modify tests in this benchmark. In a normal Django PR, add tests for:

- Wrapped constants: `ExpressionWrapper(Value(42), output_field=IntegerField()).get_group_by_cols(alias=None)` returns `[]`.
- SQL grouping: a wrapped constant annotation does not add the constant to
  `GROUP BY`.
- Legacy compatibility: a wrapped custom expression whose
  `get_group_by_cols()` lacks `alias` emits `RemovedInDjango40Warning` and calls
  the child method without the keyword.
- Alias-aware delegation: a wrapped expression that uses the alias parameter
  still receives it.

## Follow-Up Refactoring Not Required Here

The deprecation handling now appears in both `Query.set_group_by()` and
`ExpressionWrapper.get_group_by_cols()`. A future cleanup could extract a shared
helper after the deprecation period or if more wrapper classes need the same
behavior. That refactor is not required for this targeted issue.

## Residual Risk

The proof is constructed, not machine-checked. Runtime SQL generation and
database behavior were not executed. The residual risk is limited by the direct
source proof of the method branches and by preserving the public method
signature.
