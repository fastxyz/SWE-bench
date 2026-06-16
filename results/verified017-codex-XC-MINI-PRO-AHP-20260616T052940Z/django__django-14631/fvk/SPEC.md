# FVK Spec for django__django-14631

Status: constructed from source and public issue text; not machine-checked.

## Scope

This FVK pass audits the V1 changes to:

- `repo/django/forms/forms.py`: `BaseForm._bound_items()`,
  `BaseForm._clean_fields()`, and `BaseForm.changed_data`.
- `repo/django/forms/boundfield.py`: `BoundField._has_changed()`.

The proof is partial correctness over Django's form-cleaning control flow: if
the audited methods return normally, their observable values must satisfy the
postconditions below. Termination is immediate for finite `self.fields` and is
not separately machine-proved.

## Public Intent Ledger

I1. Source: prompt / issue.
Quote: "`BaseForm._clean_fields()` and `BaseForm.changed_data` don't currently
access their values through a `BoundField` object."
Obligation: both methods must obtain per-field values through the corresponding
`BoundField`, not through independent form/field lookup paths.
Status: encoded by S1-S4.

I2. Source: prompt / issue.
Quote: "It would be better for consistency if they did, and to reduce the
number of code paths."
Obligation: centralize per-bound-field behavior and preserve existing field
cleaning/change semantics.
Status: encoded by S2-S5.

I3. Source: prompt / issue.
Quote: "`form._clean_fields()` can return a different value from
`form[name].initial` when they should be the same."
Obligation: for disabled fields, the value supplied to field cleaning is the
cached `BoundField.initial`; the issue-specific `DateTimeField` callable initial
case then cleans the same initial value exposed by `form[name].initial`.
Status: encoded by S2 and S6.

I4. Source: prompt / issue.
Quote: "`changed_data()` [logic] ... could be called something like
`bf.did_change()` ... whether form data changed for a field is a property of its
`BoundField`."
Obligation: the per-field change decision must live on `BoundField`, with
`BaseForm.changed_data` aggregating names whose bound field changed.
Status: encoded by S3-S4.

I5. Source: benchmark instructions.
Quote: "Do not modify any test files" and "do not attempt to run tests, Python,
or K framework tooling".
Obligation: audit by source and constructed proof only; record commands rather
than executing them.
Status: encoded in `PROOF.md` and `ITERATION_GUIDANCE.md`.

## Formal Vocabulary

For a form `F` with finite ordered field names `Names(F)`, let:

- `BF(F, n)` be the object returned by `F[n]`.
- `Field(BF)` be `BF.field`.
- `Initial(BF)` be the cached value of `BF.initial`.
- `Data(BF)` be the value of `BF.data`.
- `HiddenInitial(BF)` be the value read from `Field(BF).hidden_widget()` at
  `BF.html_initial_name`.
- `Clean(field, value)` be `field.clean(value)`.
- `CleanFile(field, value, initial)` be `field.clean(value, initial)`.
- `HasChanged(field, initial, data)` be `field.has_changed(initial, data)`.

These are abstract observations of the Django objects; the proof does not
reimplement all field/widget semantics. It proves that `BaseForm` delegates to
the same objects and methods required by public intent.

## Specification

S1. Bound-field iteration.

`BaseForm._bound_items()` yields exactly:

```text
[(n, BF(F, n)) for n in Names(F)]
```

in field order, using `F[n]` and therefore the existing bound-field cache.

S2. Field cleaning value source.

For each `(n, BF)` produced by S1 in `_clean_fields()`:

```text
value_for_cleaning =
    Initial(BF) if Field(BF).disabled
    else Data(BF)
```

If `Field(BF)` is a `FileField`, `_clean_fields()` calls:

```text
CleanFile(Field(BF), value_for_cleaning, Initial(BF))
```

Otherwise, it calls:

```text
Clean(Field(BF), value_for_cleaning)
```

Successful results are assigned to `cleaned_data[n]`, then any existing
`clean_<n>()` hook may replace that value exactly as before V1. Any
`ValidationError` is handled by `add_error(n, error)` exactly as before V1.

S3. Changed-data aggregation.

`BaseForm.changed_data` returns:

```text
[n for (n, BF) in _bound_items(F) if BoundFieldHasChanged(BF)]
```

The order is the field order from `Names(F)`.

S4. Bound-field change predicate.

`BoundField._has_changed()` computes:

```text
if Field(BF).show_hidden_initial:
    raw_initial = HiddenInitial(BF)
    try:
        initial = Field(BF).to_python(raw_initial)
    except ValidationError:
        return True
else:
    initial = Initial(BF)
return HasChanged(Field(BF), initial, Data(BF))
```

S5. Frame conditions.

The V1 fix must not change:

- `Field.clean()`, `FileField.clean()`, or `Field.has_changed()` semantics.
- Widget data extraction semantics.
- Prefix and hidden-initial naming semantics.
- `clean_<name>()` hook order.
- Validation error handling.
- Public method signatures.

S6. Issue-specific consequence.

For the public hint's disabled callable `DateTimeField` case, `_clean_fields()`
must supply `BF.initial` to the field's `clean()` path. Since
`BoundField.initial` evaluates the callable once and applies the widget
microsecond normalization used for rendering, the cleaned value and
`form["dt"].initial` are derived from the same cached value rather than from two
separate callable evaluations.
