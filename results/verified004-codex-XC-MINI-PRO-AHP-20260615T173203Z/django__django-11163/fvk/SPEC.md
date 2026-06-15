# FVK Specification: django__django-11163

Status: constructed, not machine-checked.

## Scope

Audited unit:

- `django.forms.models.model_to_dict(instance, fields=None, exclude=None)` in
  `repo/django/forms/models.py`.

The V1 source change is the condition:

```python
if fields is not None and f.name not in fields:
```

The specification covers the observable behavior of `model_to_dict()` over the
finite field sequence obtained from `chain(opts.concrete_fields,
opts.private_fields, opts.many_to_many)`.

## Public Intent Ledger

E-001

- Source: `benchmark/PROBLEM.md`
- Evidence: "`model_to_dict() should return an empty dict for an empty list of fields.`"
- Obligation: if `fields` is explicitly provided as an empty list, the returned
  dictionary has no entries.
- Status: encoded in PO-EMPTY-FIELDS and claim `MODEL-TO-DICT-EMPTY-FIELDS`.

E-002

- Source: `benchmark/PROBLEM.md`
- Evidence: "`model_to_dict(instance, fields=[]) function should return empty dict, because no fields were requested.`"
- Obligation: the empty list is a provided inclusion filter with no selected
  names, not the same case as omitting `fields`.
- Status: encoded in PO-FIELDS-DISTINCTION.

E-003

- Source: `repo/django/forms/models.py` docstring
- Evidence: "`fields` is an optional list of field names. If provided, return only the named."
- Obligation: `fields=None` means no inclusion filter; any provided list,
  including an empty list, restricts output to names in that list.
- Status: encoded in PO-GENERAL-SELECTION.

E-004

- Source: `repo/django/forms/models.py` docstring
- Evidence: "`exclude` is an optional list of field names. If provided, exclude the named from the returned dict, even if they are listed in the `fields` argument."
- Obligation: exclusion wins over inclusion.
- Status: encoded in PO-EXCLUDE-PRECEDENCE.

E-005

- Source: `repo/django/forms/models.py` implementation shape
- Evidence: `for f in chain(opts.concrete_fields, opts.private_fields, opts.many_to_many):`
- Obligation: the proof models a finite sequence of model fields in the same
  traversal order; the order itself is implementation shape, not a new public
  ordering guarantee.
- Status: used to build the mini semantics and helper circularity.

E-006

- Source: `benchmark/PROBLEM.md` public hint
- Evidence: "fetch instance fields values without touching ForeignKey fields" and "List of fields to be fetched is an attr of the class, which can be overridden in subclasses and is empty list by default"
- Obligation: fields filtered out by the provided list are not read merely to
  construct a result that later drops them.
- Status: modeled with the proof read-log and encoded in PO-FILTER-BEFORE-READ.

E-007

- Source: `repo/django/forms/models.py` public call path
- Evidence: `object_data = model_to_dict(instance, opts.fields, opts.exclude)`
- Obligation: the direct API behavior and the ModelForm initialization path share
  the same `fields=[]` behavior.
- Status: covered by the compatibility audit and PO-CALLSITE-COMPATIBILITY.

## Contract

Domain:

- `instance._meta` supplies a finite field sequence.
- Each field has a unique model field name, an `editable` flag, and a value
  obtained by `value_from_object(instance)`.
- `fields` is either `None` or a list of field names.
- `exclude` is either `None` or a list of field names.

Postcondition:

For each field `f` in the field sequence, the returned dictionary contains
`f.name -> f.value_from_object(instance)` exactly when all of the following hold:

1. `f.editable` is truthy.
2. `fields is None` or `f.name in fields`.
3. `exclude` is not provided, or `f.name not in exclude`.

No other entries are returned. For `fields=[]`, condition 2 is false for every
field, so the returned dictionary is `{}`.

Read-log abstraction:

The formal model records a field name in a read log exactly when that field's
value is read and inserted. Therefore `fields=[]` also yields an empty read log.
This models the public hint that an empty selected-field list should not touch
unrequested field values.

## Formal Core

The constructed K artifacts are:

- `fvk/mini-python.k`: a minimal semantics for the `model_to_dict()` filtering
  loop over abstract model fields.
- `fvk/model-to-dict-spec.k`: K claims for the general selection contract, the
  helper loop/circularity, and the empty-fields corollary.

Exact commands to machine-check later, not executed in this session:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/model-to-dict-spec.k
kprove fvk/model-to-dict-spec.k
```
