# FVK Iteration Guidance

Status: constructed, not machine-checked.

## Verdict for This Iteration

V1 stands unchanged. The audit found no open production-code finding. The two V1
edits are both justified by public intent and discharged proof obligations:

- `Query.has_select_fields` is explicit state set by `Query.set_values()`.
- `RelatedIn.get_prep_lookup()` uses `Query.set_values([target_field])`.

## Decisions

D-001: Keep `has_select_fields` as explicit state.

- Traces to: F-001, PO-001, PO-002, PO-007.
- Reason: the public issue distinguishes undefined RHS selected fields from
  annotation-mask internals. A computed property over annotation masks is the
  reported failure mechanism.

D-002: Keep the `RelatedIn` `set_values([target_field])` change.

- Traces to: F-002, PO-003.
- Reason: once `has_select_fields` is explicit, target selection by
  `add_fields()` alone is not enough to stop base `In` from overwriting the
  related target with pk.

D-003: Do not add clone-specific code.

- Traces to: F-003, PO-004.
- Reason: `set_values()` creates instance state, and `Query.clone()` already
  copies instance state with `__dict__.copy()`.

D-004: Do not change base `In` or `Exact` to call `set_values(["pk"])`.

- Traces to: F-004, PO-002, PO-006.
- Reason: default pk injection is lookup preparation, not user explicit
  selection. The downstream overwrite risk is already handled in `RelatedIn`.

D-005: Do not make public compatibility edits.

- Traces to: F-005, PO-005.
- Reason: V1 does not change public signatures, return types, or test files.

## Recommended Follow-Up Tests

No tests were added or run in this benchmark setting. After leaving this
restricted environment, useful regression coverage would be:

- `annotate().alias()` RHS query in `__in` without `values()` narrows to one pk
  column.
- Explicit `values()` and `values_list()` RHS queries are preserved by `__in`.
- Related non-primary-key `__in` RHS queries select the related target field,
  including the nested case called out by the public hint.
- Sliced one-row `Exact` RHS queries use the same discriminator behavior.

Do not remove existing tests based on this proof unless the K artifacts are
machine-checked and the Django tests also pass.

## Residual Risks

- The proof is constructed, not machine-checked.
- The model abstracts the ORM to query-selection state; it does not model SQL
  compilation, join construction, or database execution.
- Hidden tests and benchmark results were not used and remain unknown.

## Next Iteration Trigger

Only revisit production code if one of the following happens:

- K machine checking finds a formalization error in `fvk/mini-django-query.k` or
  `fvk/query-in-spec.k`.
- A public test or source audit reveals another lookup path that uses
  `has_select_fields` after a non-`set_values()` field injection.
- Public API evidence shows external code relies on `Query.has_select_fields`
  meaning "the SQL SELECT tuple is non-empty" rather than "values-style selected
  fields are explicit".
