# Proof Obligations

Status: constructed, not machine-checked.

The obligations below are the formal checkpoints used to audit V1 against
`fvk/SPEC.md`. They are written in a K-style reachability vocabulary, but no K
tooling was executed.

## Abstract Claim Skeleton

The audited transition can be viewed as:

```k
// SPEC-PROVENANCE:
// - I1/I3: cleaning values must flow through BoundField.
// - I2/I4: changed_data per-field decision belongs to BoundField.
claim
  <k> auditForm(FORM) => audited(CLEANED, CHANGED) ... </k>
  <fields> NAMES </fields>
  <boundFields> BFMAP </boundFields>
  <cleaned> .Map => CLEANED </cleaned>
  <changed> .List => CHANGED </changed>
  requires BFMAP ==K boundFieldsFor(FORM, NAMES)
  ensures CLEANED ==K cleanViaBoundFields(FORM, NAMES, BFMAP)
   andBool CHANGED ==K changedViaBoundFields(FORM, NAMES, BFMAP)
  [all-path]
```

This is an abstraction over Django objects. The proof obligations below make
the abstraction concrete enough to distinguish the reported bug from the fixed
behavior.

## Obligations

PO1. Bound-field cache identity.

For each field name `n` in `self.fields`, `self[n]` returns the cached
`BoundField` for that `(form, field, name)` pair, creating it through
`field.get_bound_field(self, n)` only on first access.

- Supports: `SPEC.md` S1.
- Discharged by source: `BaseForm.__getitem__()`.

PO2. Bound-field iteration completeness and order.

`BaseForm._bound_items()` yields exactly one `(name, self[name])` pair for each
name in `self.fields`, in `self.fields` iteration order.

- Supports: `SPEC.md` S1 and S3.
- Discharged by source: the V1 `_bound_items()` generator.

PO3. Enabled-field data source.

For any non-disabled field `field`, `_clean_fields()` uses `bf.data`, which is
defined as `form._field_data_value(field, bf.html_name)`.

- Supports: `SPEC.md` S2.
- Discharged by source: `BaseForm._clean_fields()` and `BoundField.data`.

PO4. Disabled-field initial source.

For any disabled field `field`, `_clean_fields()` uses `bf.initial` as the
value supplied to field cleaning.

- Supports: `SPEC.md` S2, S6 and `FINDINGS.md` F1.
- Discharged by source: `BaseForm._clean_fields()` V1 assignment
  `value = bf.initial if field.disabled else bf.data`.

PO5. `FileField` initial source.

For any `FileField`, `_clean_fields()` supplies `bf.initial` as the second
argument to `field.clean(value, initial)`.

- Supports: `SPEC.md` S2 and `FINDINGS.md` F2.
- Discharged by source: `BaseForm._clean_fields()` V1 `FileField` branch.

PO6. Cleaning frame condition.

Aside from the source of `value` and `initial`, `_clean_fields()` preserves
field-specific `clean()`, `clean_<name>()`, `cleaned_data`, and
`ValidationError` handling behavior.

- Supports: `SPEC.md` S5.
- Discharged by source: V1 retains the original try/except block, assignment
  order, and hook invocation.

PO7. Non-hidden changed-data equivalence.

For fields where `field.show_hidden_initial` is false,
`BoundField._has_changed()` returns:

```text
field.has_changed(bf.initial, bf.data)
```

- Supports: `SPEC.md` S4 and `FINDINGS.md` F3.
- Discharged by source: `BoundField._has_changed()` else branch.

PO8. Hidden-initial changed-data equivalence.

For fields where `field.show_hidden_initial` is true,
`BoundField._has_changed()`:

1. reads the hidden initial through `field.hidden_widget()` and
   `bf.html_initial_name`;
2. converts it with `field.to_python()`;
3. returns `True` if that conversion raises `ValidationError`;
4. otherwise returns `field.has_changed(converted_initial, bf.data)`.

- Supports: `SPEC.md` S4 and `FINDINGS.md` F4.
- Discharged by source: `BoundField._has_changed()` hidden-initial branch.

PO9. Changed-data aggregation.

`BaseForm.changed_data` returns exactly the names from `_bound_items()` whose
bound fields satisfy `_has_changed()`, preserving field order and the
`cached_property` behavior.

- Supports: `SPEC.md` S3 and `FINDINGS.md` F3.
- Discharged by source: V1 list comprehension in `BaseForm.changed_data`.

PO10. Issue-specific DateTime consequence.

For a disabled `DateTimeField` whose initial is callable, `_clean_fields()` and
`form[name].initial` share the same `BoundField.initial` value. The callable is
not evaluated on an independent `_clean_fields()` path.

- Supports: `SPEC.md` S6 and `FINDINGS.md` F1.
- Discharged by PO1, PO2, and PO4, plus existing `BoundField.initial`
  `cached_property` behavior.

PO11. Public compatibility frame condition.

The patch adds private helpers but does not change public method signatures or
the return shape of public methods.

- Supports: `SPEC.md` S5 and `FINDINGS.md` F5.
- Discharged by source diff review: new methods are private
  `_bound_items()` and `_has_changed()`, and existing public signatures remain
  unchanged.

## Commands To Machine-Check Later

The benchmark forbids running these commands. They are recorded as the commands
that would be used after extracting the abstract claim skeleton into a concrete
K definition:

```sh
kompile fvk/mini-django-forms.k --backend haskell
kast --backend haskell fvk/django-forms-spec.k
kprove fvk/django-forms-spec.k
```

Expected result after a faithful concrete K encoding: `#Top` for PO1-PO11.
