# FVK Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Claims

The formal claims are in `fvk/default-pk-spec.k` and use the semantics in
`fvk/mini-default-pk.k`.

The central predicate is:

```text
warn =
  PK_AUTO_CREATED
  and PK_IS_AUTO_FIELD
  and not DEFAULT_SETTING_OVERRIDDEN
  and not APP_DEFAULT_AUTO_FIELD_OVERRIDDEN
```

This matches the V1 source predicate in `Model._check_default_pk()`:

```text
cls._meta.pk.auto_created
and cls._meta.pk is cls._meta.auto_field
and not settings.is_overridden('DEFAULT_AUTO_FIELD')
and not cls._meta.app_config._is_default_auto_field_overridden
```

## Constructed Proof Sketch

1. Symbolic execution of `checkDefaultPk(PK_AUTO_CREATED, PK_IS_AUTO_FIELD,
   DEFAULT_SETTING_OVERRIDDEN, APP_DEFAULT_AUTO_FIELD_OVERRIDDEN)` rewrites in
   one semantic step to `warnCondition(...)`.

2. `warnCondition(...)` rewrites to the conjunction above.

3. For an inherited parent-link primary key, source inspection gives
   `PK_AUTO_CREATED=true`, `PK_IS_AUTO_FIELD=false`,
   `DEFAULT_SETTING_OVERRIDDEN=false`, and
   `APP_DEFAULT_AUTO_FIELD_OVERRIDDEN=false`. Substitution reduces the
   conjunction to `true and false and true and true`, which is `false`.
   Therefore the warning is not emitted, discharging PO1.

4. For an implicit default auto primary key, source inspection gives
   `PK_AUTO_CREATED=true`, `PK_IS_AUTO_FIELD=true`, and both override flags
   false. Substitution reduces the conjunction to `true`, so W042 is emitted,
   discharging PO2.

5. For an explicit primary key, `PK_AUTO_CREATED=false`. The conjunction is
   false regardless of the other fields, discharging PO3.

6. For either override flag set to true, the corresponding negated override
   conjunct is false. The conjunction is false, preserving the pre-existing
   suppression behavior and discharging PO5.

## Metadata Lemma

The proof depends on PO4, the metadata discriminator:

- On the implicit default path, `Options._prepare()` constructs
  `pk_class(verbose_name='ID', primary_key=True, auto_created=True)` and adds it
  to the model. `AutoFieldMixin.contribute_to_class()` then records the same
  field as `cls._meta.auto_field`.
- On the inherited parent-link path, `ModelBase` constructs a
  `OneToOneField(..., auto_created=True, parent_link=True)`.
  `Options._prepare()` may promote that relation field to primary key, but it is
  not an `AutoFieldMixin` field and is not recorded as `cls._meta.auto_field`.

Thus `pk.auto_created` alone conflates the two cases, while
`pk.auto_created and pk is auto_field` distinguishes them.

## Machine-Check Commands

These commands are required to upgrade the proof from constructed to
machine-checked. They were not executed in this task.

```sh
kompile fvk/mini-default-pk.k --backend haskell
kast --backend haskell fvk/default-pk-spec.k
kprove fvk/default-pk-spec.k
```

Expected result after a successful machine check: `#Top`.

## Test Guidance

No tests were run and no test files were modified. Do not remove tests based on
this constructed proof. A regression test should cover a child model inheriting
a manually specified primary key from a concrete parent, but adding tests is
outside this task's permitted edits.
