# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbol or Producer

`repo/sphinx/domains/python.py`: the `PyTypedField('variable', ...)`
construction in `PyObject.doc_field_types`.

## Compatibility Checks

| Surface | Result | Evidence |
| --- | --- | --- |
| Public constructor signatures | Compatible | `PyTypedField.__init__` and `Field.__init__` are unchanged. V1 only omits an optional keyword at one construction site. |
| Public method signatures | Compatible | `Field.make_xref()`, `TypedField.make_field()`, `PyXrefMixin.make_xref()`, and `PythonDomain.find_obj()` signatures are unchanged. |
| Python explicit roles | Compatible | No changes to `PythonDomain.roles`, `PyXrefMixin`, or `PythonDomain.find_obj()`. |
| Type field behavior | Compatible | `typerolename='class'` remains on the variable field, preserving `vartype` type links. |
| Field label rendering | Intentional behavior change | `var`/`ivar`/`cvar` labels no longer auto-link. This is the requested fix and is supported by public docs that describe them as variable descriptions. |
| Other Python-domain variable-field producers | Compatible | Repository search found only one `PyTypedField('variable', ...)` producer in the Python domain. |

## Compatibility Conclusion

The change has no public API/signature impact. The only output behavior change
is the intended removal of implicit cross-reference nodes from Python variable
field labels.
