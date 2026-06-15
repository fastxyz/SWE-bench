# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found that the one-line source change in
`repo/django/db/models/fields/related.py` discharges the manager-selection
obligation without introducing a compatibility issue.

## Trace to findings and proof obligations

`F1` identifies the operative bug: a row visible through `_base_manager` but
hidden by `_default_manager` was rejected as missing. `PO1` requires accepting
that row when explicit relation limits allow it. V1 satisfies both by changing
the existence query in `ForeignKey.validate()` from
`remote_field.model._default_manager` to `remote_field.model._base_manager`.

`F2` and `PO3` require preserving `limit_choices_to`. No additional edit was
made because V1 leaves `qs = qs.complex_filter(self.get_limit_choices_to())`
unchanged after the manager swap.

`PO2` requires preserving database routing. No additional edit was made because
V1 leaves `using = router.db_for_read(self.remote_field.model,
instance=model_instance)` unchanged and continues to call `.using(using)` on the
chosen manager.

`PO4` requires preserving invalid behavior for values with no base-manager row.
No additional edit was made because V1 still raises the existing
`ValidationError` when `not qs.exists()`.

`F3` and `PO5` found no public compatibility blocker. The method signature,
return convention, exception type, error payload, form call path, and formfield
construction APIs are unchanged, so no compatibility repair was needed.

`PO6` localizes the legacy symptom to the default-manager branch. V1 removes
that branch from `ForeignKey.validate()`'s existence query, so the audit did not
justify further source changes.

## Formal-verification caveat

The FVK proof is constructed over the minimal abstract model in
`fvk/mini-django-validation.k` and the claims in
`fvk/foreignkey-validate-spec.k`. Per the task restriction, no K tooling,
Python, or Django tests were run. The proof remains "constructed, not
machine-checked"; the source decision rests on the public intent ledger,
source-level audit, and constructed proof obligations.
