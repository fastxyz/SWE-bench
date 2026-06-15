# Formal Spec English

Status: constructed for audit; not machine-checked.

## K claim paraphrases

`FK_BASE_MANAGER_ACCEPTS`:
For any submitted foreign key value, if the related row exists according to the
base manager and explicit relation limits allow the value, V1 validation returns
valid even when the default manager would not see the row.

`FK_BASE_MANAGER_REJECTS_MISSING`:
For any submitted foreign key value, if the related row does not exist according
to the base manager, V1 validation returns invalid.

`FK_LIMIT_CHOICES_STILL_APPLIES`:
For any submitted foreign key value, if the related row exists according to the
base manager but explicit relation limits reject the value, V1 validation
returns invalid.

`FK_LEGACY_DEFAULT_MANAGER_FAILS_ARCHIVED`:
For the public archived-row example, a legacy implementation using the default
manager can return invalid when the base manager would return valid. This
explains the reported symptom and is not a desired behavior claim.

## Frame conditions

The formal model abstracts away unrelated field validation, routing internals,
and `ValidationError` formatting. The audit keeps those behaviors framed by
source inspection: V1 changed only the manager used for the existence query.
