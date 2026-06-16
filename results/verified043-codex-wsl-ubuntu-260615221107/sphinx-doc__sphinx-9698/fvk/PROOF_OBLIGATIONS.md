# Proof Obligations

Constructed, not machine-checked.

## PO-1: Qualified property index entries omit callable parentheses

For every qualified name `CLS.METH`, module state, and `add_module_names` flag,
if `property in self.options`, `PyMethod.get_index_text()` must return the
property format `METH (displayed_cls property)`, not `METH() (...)`.

Linked findings: F-001, F-002, F-003.

## PO-2: Unqualified property index entries omit callable parentheses

For every unqualified `NAME`, if `property in self.options`, the no-module form
must be `NAME` and the module form must be `NAME (in module MOD)`.

Linked findings: F-003.

## PO-3: Property option has precedence over callable variants

If `property in self.options`, the selected index branch must be property-shaped
even when `classmethod` or `staticmethod` is also present.

Linked findings: F-001, F-003.

## PO-4: Non-property callable method formats are preserved

If `property not in self.options`, existing method/classmethod/staticmethod
index entries remain callable-shaped and include `()`.

Linked findings: F-003.

## PO-5: Module-name display behavior is preserved

For qualified names, `modname` and `add_module_names` affect only the displayed
class name exactly as before: `MOD.CLS` when enabled and `CLS` otherwise.

Linked findings: F-003.

## PO-6: Index append protocol is preserved

`PyObject.add_target_and_index()` must continue to append the returned string as
the single-index entry when `noindexentry` is absent.

Linked findings: F-003.

## PO-7: Domain registration and cross-reference compatibility are preserved

The fix must not change `domain.note_object(fullname, self.objtype, ...)`,
canonical alias registration, node ids, or cross-reference roles.

Linked findings: F-003.

## PO-8: Verification honesty

All proof results are constructed, not machine-checked; no test deletion or
machine-verified claim is justified until the recorded `kprove` command returns
`#Top`.

Linked findings: F-002, F-004.
