# FVK Spec

Status: constructed, not machine-checked.

## Target

The target is the Python-domain info-field pipeline for variable fields:

- `repo/sphinx/domains/python.py`: `PyObject.doc_field_types`
- `repo/sphinx/util/docfields.py`: `Field.make_xref()` and
  `TypedField.make_field()`
- `repo/sphinx/domains/python.py`: `PyXrefMixin.make_xref()` and
  `PythonDomain.find_obj()` as the downstream resolver that used to make the
  wrong link possible

## Public Intent Ledger

Critical public intent entries are mirrored from
`fvk/PUBLIC_EVIDENCE_LEDGER.md`:

- E1-E4: variable documentation labels must not automatically link to
  same-name objects elsewhere.
- E3: same-module global-variable fallback is also wrong for class variable
  documentation, so merely removing suffix/fuzzy lookup would be incomplete.
- E5: explicit roles are the opt-in linking mechanism and should remain
  unchanged.
- E6-E7: public docs say `var`/`ivar`/`cvar` describe a variable, while
  `vartype` creates type links if possible.
- E8-E10: the implementation path confirms that removing `rolename` from the
  variable field prevents `pending_xref` creation at the source and leaves
  `typerolename='class'` intact.

## Informal Contract

For every variable field name `N` and content `C` inside a Python object
description, regardless of what same-name Python objects exist in the domain
inventory:

1. Rendering `:var N: C`, `:ivar N: C`, or `:cvar N: C` produces a plain field
   label for `N`, not a `pending_xref`.
2. Because no `pending_xref` exists for `N`, Python-domain resolution cannot
   replace the label with a reference to `module.N`, `OtherClass.N`, or any
   suffix match `.N`.
3. If the variable has type text `T` from `:vartype N: T` or an inline typed
   variable field, `T` still uses the Python `class` type-reference machinery.
4. Explicit roles written by the user, such as `:py:const:`N`` or
   `:py:data:`N``, are not changed by this contract.

## Formal Model

The K files model only the property-carrying slice:

- `fvk/mini-sphinx-fields.k` defines field-label rendering and a symbolic
  object inventory containing same-name module/class/other-class cases.
- `fvk/sphinx-fields-spec.k` states the claims:
  - `VARIABLE-FIELD-NO-XREF`
  - `VARIABLE-FIELD-WITH-TYPE-PRESERVES-TYPE-XREF`
  - `EXPLICIT-REFERENCE-STILL-LINKS`

The model deliberately abstracts away docutils node internals not needed for
the property. It keeps the observable distinction that matters for this issue:
`plain(NAME)` versus `linked(NAME, TARGET_KIND)` / `pending(ROLE, NAME)`.

## Frame Conditions

- No public constructor or method signature changes.
- No changes to explicit Python roles or `PythonDomain.find_obj()`.
- No changes to Python object inventory registration.
- No changes to type-link generation for `type`, `vartype`, or `rtype`.

## Conclusion

The V1 source change satisfies the intent contract. No source revision is
required by the FVK audit.
