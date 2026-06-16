# FVK Proof Obligations

Status: constructed, not machine-checked.

## PO1: No warning for inherited manually specified primary keys

For any model where `cls._meta.pk.auto_created=true` only because Django
promoted a concrete ancestor parent link to the child primary key, and where
`cls._meta.pk is cls._meta.auto_field=false`, `_check_default_pk()` must return
`[]`.

Source: prompt evidence E1 and E2.

Status: discharged by V1 predicate and `default-pk-spec.k` parent-link claim.

## PO2: Warning for implicit default auto primary keys

For a model with an implicit default auto primary key where
`cls._meta.pk.auto_created=true`, `cls._meta.pk is cls._meta.auto_field=true`,
and neither default-auto-field override is present, `_check_default_pk()` must
return exactly one `models.W042` warning.

Source: warning semantics and public in-repo check tests.

Status: discharged by V1 predicate and `default-pk-spec.k` implicit-default
claim.

## PO3: No warning for explicit primary keys

For a model with an explicit primary key where `cls._meta.pk.auto_created=false`,
`_check_default_pk()` must return `[]`, even if the field is an `AutoField`
subclass recorded as `_meta.auto_field`.

Source: public in-repo check tests.

Status: discharged by the `pk.auto_created` conjunct retained from the original
implementation.

## PO4: Metadata discriminator is valid

The proof may rely on `cls._meta.pk is cls._meta.auto_field` to distinguish the
implicit default auto primary key from an inherited parent-link primary key.

Source: implementation evidence:

- `Options._prepare()` creates `pk_class(..., auto_created=True)` only on the
  no-parent implicit default `id` path.
- `AutoFieldMixin.contribute_to_class()` records an `AutoField` as
  `cls._meta.auto_field`.
- `ModelBase` creates the inheritance parent link as `OneToOneField(...,
  auto_created=True, parent_link=True)`, and `Options._prepare()` promotes it to
  primary key without going through `AutoFieldMixin`.

Status: discharged by source inspection.

## PO5: Preserve public API and warning payload

The fix must not change the public method signature, warning ID, warning text,
hint text, return shape, or existing setting/app override behavior.

Source: compatibility audit and existing code contract.

Status: discharged. The source edit changes only the internal predicate before
the existing `checks.Warning` object is constructed.

## PO6: Honesty gate

The proof must be labeled as constructed, not machine-checked, and must not
claim test removal or runtime confirmation because this environment forbids
running tests, Python, or K tooling.

Source: FVK verify instructions and task constraints.

Status: discharged by artifact labeling and by recording commands without
executing them.
