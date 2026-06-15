# Proof Obligations

Status: constructed, not machine-checked.

## PO1 - Base-manager acceptance

For any value `v`, if `baseExists(v)` and `limitAllows(v)`, then
`ForeignKey.validate(v, instance)` must not reject `v` solely because
`defaultExists(v)` is false.

- Evidence: E1, E2, E3, E4.
- K claim: `FK_BASE_MANAGER_ACCEPTS`.
- V1 discharge: the code constructs `qs` from
  `self.remote_field.model._base_manager.using(using)`.

## PO2 - Routing is preserved

The database alias used by validation remains the result of
`router.db_for_read(self.remote_field.model, instance=model_instance)`.

- Evidence: E8.
- V1 discharge: the line computing `using` is unchanged.

## PO3 - Explicit relation limits are preserved

After the base-manager existence query is built, validation still applies
`complex_filter(self.get_limit_choices_to())`.

- Evidence: E6.
- K claim: `FK_LIMIT_CHOICES_STILL_APPLIES`.
- V1 discharge: the `complex_filter()` line is unchanged.

## PO4 - Missing base-manager rows are still invalid

If no related row exists through `_base_manager`, validation must raise the
existing invalid `ValidationError`.

- Evidence: E4.
- K claim: `FK_BASE_MANAGER_REJECTS_MISSING`.
- V1 discharge: the code still raises when `not qs.exists()`.

## PO5 - Public compatibility is preserved

No public method signature, caller contract, exception type, or form API changes.

- Evidence: E5, compatibility source inspection.
- V1 discharge: only the manager attribute in the query construction changed.

## PO6 - Legacy symptom is localized

The V0 behavior is explained by the default-manager branch:
`baseExists=true`, `defaultExists=false`, `limitAllows=true` leads to invalid
under `DefaultManager`.

- Evidence: E3.
- K claim: `FK_LEGACY_DEFAULT_MANAGER_FAILS_ARCHIVED`.
- V1 discharge: the audited production code no longer uses `DefaultManager` for
  this validation query.
