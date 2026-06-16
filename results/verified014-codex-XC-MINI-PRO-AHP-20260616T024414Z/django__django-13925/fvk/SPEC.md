# FVK Spec: `models.W042` Default Primary Key Check

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited unit is `Model._check_default_pk()` in
`repo/django/db/models/base.py`. Its observable behavior is whether the model
check returns a `models.W042` warning or returns no warning. The audit also
uses the producer-side metadata paths in `Options._prepare()` and
`AutoFieldMixin.contribute_to_class()` to justify the discriminator used by the
check.

## Intent Spec

1. Inherited manually specified primary keys must not emit `models.W042`.
   Evidence: the issue title says "`models.W042` is raised on inherited
   manually specified primary key" and the report says, "These models should
   not use auto-created primary keys! I already defined the primary key in the
   ancestor of the model."

2. Ordinary implicit default auto primary keys must continue to emit `models.W042`
   when neither `DEFAULT_AUTO_FIELD` nor `AppConfig.default_auto_field` was
   overridden.
   Evidence: the warning text says it is for an "Auto-created primary key used
   when not defining a primary key type"; public in-repo tests under
   `tests/check_framework/test_model_checks.py` assert this warning for a model
   with no declared primary key.

3. Explicit primary keys must not emit `models.W042`.
   Evidence: public in-repo tests under
   `tests/check_framework/test_model_checks.py` assert no warning when an
   explicit primary key is declared.

4. The existing suppression behavior for `DEFAULT_AUTO_FIELD` and
   `AppConfig.default_auto_field` overrides must be preserved.
   Evidence: the pre-existing check included these suppression conditions and
   public in-repo tests exercise them.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`models.W042` is raised on inherited manually specified primary key." | A child model whose primary key is inherited through its parent must not be classified as lacking a primary key type. | Encoded in `default-pk-spec.k` parent-link claim. |
| E2 | prompt | "I already defined the primary key in the ancestor of the model." | Ancestor-defined primary keys are outside the `DEFAULT_AUTO_FIELD` warning case. | Encoded by requiring `_meta.pk is _meta.auto_field` before warning. |
| E3 | public-test/code | `test_auto_created_pk` expects W042 for a model with no primary key declaration. | Preserve W042 for implicit default auto fields. | Encoded in implicit-default claim. |
| E4 | public-test/code | Explicit primary key checks expect no warning. | Preserve no-warning behavior for explicit primary keys. | Encoded in explicit-primary-key claim. |
| E5 | implementation | `Options._prepare()` creates `pk_class(..., auto_created=True)` only for the implicit default `id` path with no parents. | Default auto primary keys have `pk.auto_created=true`. | Used as implementation evidence for the K input mapping. |
| E6 | implementation | `AutoFieldMixin.contribute_to_class()` sets `cls._meta.auto_field = self`. | Default and explicit `AutoField` primary keys are recorded as `_meta.auto_field`. | Used as implementation evidence for the K input mapping. |
| E7 | implementation | Multi-table inheritance creates a `OneToOneField(..., auto_created=True, parent_link=True)` and later promotes it to `primary_key=True`. | Parent-link primary keys can have `pk.auto_created=true` but are not `_meta.auto_field`. | Encoded in parent-link claim. |

## Formal Model

The formal model abstracts a model's metadata to four booleans:

- `PK_AUTO_CREATED`: `cls._meta.pk.auto_created`
- `PK_IS_AUTO_FIELD`: `cls._meta.pk is cls._meta.auto_field`
- `DEFAULT_SETTING_OVERRIDDEN`: `settings.is_overridden('DEFAULT_AUTO_FIELD')`
- `APP_DEFAULT_AUTO_FIELD_OVERRIDDEN`:
  `cls._meta.app_config._is_default_auto_field_overridden`

The intended warning predicate is:

```text
warn =
  PK_AUTO_CREATED
  and PK_IS_AUTO_FIELD
  and not DEFAULT_SETTING_OVERRIDDEN
  and not APP_DEFAULT_AUTO_FIELD_OVERRIDDEN
```

This is represented in `fvk/mini-default-pk.k` and exercised by the claims in
`fvk/default-pk-spec.k`.

## Formal Spec English

1. If a primary key is auto-created but is not the model's `_meta.auto_field`,
   and no setting or app override is present, `_check_default_pk()` returns no
   W042 warning.

2. If a primary key is auto-created, is the model's `_meta.auto_field`, and no
   setting or app override is present, `_check_default_pk()` returns W042.

3. If a primary key is not auto-created, `_check_default_pk()` returns no W042
   warning even when the field is `_meta.auto_field`.

4. If either the project-level or app-level default-auto-field setting is
   overridden, `_check_default_pk()` returns no W042 warning for this check.

## Adequacy Audit

The formal spec passes the intent audit. It is not weaker than the issue because
the inherited parent-link case is explicitly represented by
`PK_AUTO_CREATED=true` and `PK_IS_AUTO_FIELD=false`; the model can distinguish
the failing pre-V1 case from the intended implicit-default warning case. It is
not stronger than public intent because it preserves the existing override
conditions and explicit-primary-key behavior.

## Public Compatibility Audit

No public function signature, return type, warning ID, warning text, or hint text
is changed. The source edit only narrows the internal predicate that decides
whether to construct the existing `checks.Warning`. No public caller or subclass
override compatibility issue was found.
