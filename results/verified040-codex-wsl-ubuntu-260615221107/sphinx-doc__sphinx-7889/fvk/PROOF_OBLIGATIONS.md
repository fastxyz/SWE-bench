# Proof Obligations

Status key: `DISCHARGED-CONSTRUCTED` means discharged by static proof
construction, not by running `kprove` or tests.

## PO1: `_make_subclass_name` returns a string on the intended domain

- Proven unit: `_make_subclass_name(name)`.
- Precondition: `name` is in the public issue's ordinary generic-parameter
  domain: a string, an object with string `__name__`, or an object with ordinary
  Python string-producing `repr()`.
- Postcondition: return value is `str`.
- Supports findings: F1, F3.
- Status: DISCHARGED-CONSTRUCTED.

Case split:

- `isinstance(name, str)`: returns `name`, a string.
- `name_attr = getattr(name, "__name__", None)` and `isinstance(name_attr, str)`:
  returns `name_attr`, a string.
- Otherwise: returns `repr(name)`, a string by the named default-domain
  assumption for ordinary objects.

## PO2: TypeVar-like names normalize to their string `__name__`

- Proven unit: `_make_subclass_name(name)`.
- Precondition: `name` is a `typing.TypeVar`-like object with string
  `name.__name__ == T`.
- Postcondition: return value is `T`.
- Supports findings: F1.
- Status: DISCHARGED-CONSTRUCTED.

This matches Sphinx's existing `sphinx.util.typing.stringify()` convention for
`TypeVar`, which returns `annotation.__name__`.

## PO3: Existing string-name behavior is preserved

- Proven unit: `_make_subclass_name(name)` and `_make_subclass(name, module, ...)`.
- Precondition: `name` and `module` are strings.
- Postcondition: normalized name is the original `name`, and display name remains
  `module + "." + name`.
- Supports findings: F2.
- Status: DISCHARGED-CONSTRUCTED.

## PO4: `_make_subclass` no longer performs `str + non_str`

- Proven unit: `_make_subclass(name, module, superclass, attributes)`.
- Precondition: `module` is a string and PO1 holds for `name`.
- Postcondition: the display-name expression is `module + "." + normalized_name`
  where `normalized_name` is a string; the first argument to `type()` is also a
  string.
- Supports findings: F1, F3.
- Status: DISCHARGED-CONSTRUCTED.

## PO5: `_MockObject.__getitem__` reaches the safe helper path for generic keys

- Proven unit: `_MockObject.__getitem__(key)`.
- Precondition: `key` is in the in-domain generic-parameter set from PO1.
- Postcondition: subscript access delegates to `_make_subclass(key, display,
  cls)` and therefore inherits PO4.
- Supports findings: F1.
- Status: DISCHARGED-CONSTRUCTED.

## PO6: Non-string fabricated `__name__` attributes are not trusted

- Proven unit: `_make_subclass_name(name)`.
- Precondition: `getattr(name, "__name__", None)` yields a non-string value.
- Postcondition: helper does not return that value; it uses `repr(name)` instead.
- Supports findings: F3.
- Status: DISCHARGED-CONSTRUCTED.

## PO7: Public compatibility is preserved

- Proven unit: public/semi-public call shape.
- Precondition: existing callers use the same arity as before.
- Postcondition: string-name callers receive the same dotted display behavior,
  and generic-key callers are newly accepted rather than rejected.
- Supports findings: F2, F4.
- Status: DISCHARGED-CONSTRUCTED.

## Machine-Check Commands

These commands are specified for a future environment with K installed. They
were not run here.

```sh
cd fvk
kompile mini-python-mock.k --backend haskell
kast --backend haskell autodoc-mock-spec.k
kprove autodoc-mock-spec.k
```
