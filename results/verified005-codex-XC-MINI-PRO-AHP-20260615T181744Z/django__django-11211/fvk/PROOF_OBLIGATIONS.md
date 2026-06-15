# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO-001: UUID preparation canonicalizes valid textual UUID values

Statement: For every valid UUID string `S`, `UUIDField.get_prep_value(S) == UUIDField.to_python(S) == uuid.UUID(S)`.

Evidence: I-001, I-005, C-001.

V1 discharge: `UUIDField.get_prep_value()` now calls `super().get_prep_value(value)` for base Promise handling and then `self.to_python(value)`.

## PO-002: GFK source key equals related-object key for UUID primary keys

Statement: For valid UUID string `S` and target class `Foo`, `GenericForeignKey.gfk_key(source)` returns `(uuid.UUID(S), Foo)`, matching `rel_obj_attr(target)` returning `(target.pk, target.__class__)`.

Evidence: I-001, I-002, I-005, C-002.

V1 discharge: PO-001 converts the source side to `uuid.UUID(S)`. Existing backend converters make loaded `UUIDField` primary keys Python `uuid.UUID` values, and `target.__class__` matches `ContentType.model_class()` for the in-domain target model.

## PO-003: Matched prefetch key populates the single relation cache

Statement: If `rel_obj_attr(rel_obj) == instance_attr(instance)` and the relation is single, `prefetch_one_level()` assigns that related object rather than `None`.

Evidence: I-002 and `repo/django/db/models/query.py` dictionary lookup in `prefetch_one_level()`.

V1 discharge: Once PO-002 holds, `vals` is non-empty and the existing `single` branch assigns `val = vals[0]`.

## PO-004: Null object ids remain skipped

Statement: `None` object ids are not queried or matched during GFK prefetch, and UUID preparation preserves `None`.

Evidence: C-003 and existing `GenericForeignKey.get_prefetch_queryset()` `if fk_val is not None` guard.

V1 discharge: `UUIDField.get_prep_value(None)` calls `to_python(None)`, which returns `None`; the GFK prefetch code already skips null object ids before preparation.

## PO-005: Database preparation remains compatible after earlier UUID preparation

Statement: ORM lookups that call `UUIDField.get_prep_value()` before `UUIDField.get_db_prep_value(..., prepared=True)` still produce backend-compatible parameters.

Evidence: `repo/django/db/models/lookups.py` prepares RHS values before DB prep; `UUIDField.get_db_prep_value()` accepts `uuid.UUID` and returns native UUID when supported or `value.hex` otherwise.

V1 discharge: V1 changes valid string input into `uuid.UUID`; existing DB prep already handles that object form.

## PO-006: Public API and documented GFK limitations are preserved

Statement: The fix must not add direct `GenericForeignKey` filtering or change public method signatures.

Evidence: I-003 and public compatibility audit in `fvk/SPEC.md`.

V1 discharge: only `UUIDField.get_prep_value(self, value)` is added with the base field signature; no GFK filtering path is modified.

## PO-007: Existing non-UUID preparation behavior is not weakened

Statement: The GFK prefetch algorithm should continue delegating target-key normalization to the target primary key field, preserving existing integer and string primary-key behavior.

Evidence: I-004 and existing tests for GFK prefetch and CharField object id handling.

V1 discharge: `GenericForeignKey.get_prefetch_queryset()` is unchanged. The change is confined to UUIDField, the field whose preparation was missing.

## PO-008: Honesty gate

Statement: The proof must be labeled constructed, not machine-checked, and tests/tooling must not be run or inferred.

Evidence: F-004 and the task's no-execution rule.

V1 discharge: artifacts include exact commands but no command execution was attempted.
