# FVK Specification

Constructed, not machine-checked.

## Scope

This FVK pass audits the V1 fix for `sphinx-doc__sphinx-9698`, focused on the
observable index-entry text produced by `PyMethod.get_index_text()` and consumed
by `PyObject.add_target_and_index()`.

The formal core is:

- `fvk/mini-python-domain.k`
- `fvk/python-domain-index-spec.k`

Exact commands to run later, not run in this session:

```sh
kompile fvk/mini-python-domain.k --backend haskell
kast --backend haskell fvk/python-domain-index-spec.k
kprove fvk/python-domain-index-spec.k
```

## Intent Ledger

| ID | Source | Evidence | Obligation |
| --- | --- | --- | --- |
| E1 | prompt | "`py:method` directive with `:property:` option" | The relevant unit is `PyMethod` index formatting when `property` is present. |
| E2 | prompt | "It should not have parens." | A property-option index entry must not include callable `()`. |
| E3 | prompt | Reproduction compares `py:method Foo.bar :property:` and `py:property Foo.baz`. | `py:method :property:` should match property index shape. |
| E4 | source | `PyMethod.needs_arglist()` returns `False` for `property`. | Signature and index should agree that the object is non-callable for this option. |
| E5 | source | `PyProperty.get_index_text()` omits `()`. | Existing property directive provides the local reference format. |
| E6 | public-test | Existing assertion expects `meth5() (Class property)`. | SUSPECT legacy test because it encodes the reported bug. |
| E7 | source | `add_target_and_index()` appends `get_index_text()` and separately notes the object. | Text change is sufficient; registration and node ids are frame conditions. |

## Contract

Preconditions:

- `name_cls[0]` is the full name produced by `PyObject.handle_signature()`.
- `modname` is either absent or a string module name.
- `self.env.config.add_module_names` is a boolean.
- `self.options` is a directive option map accepted by `PyMethod`.

Postconditions:

- PO-1: If `property in self.options` and the object name is qualified, the
  index text is `methname (clsname property)` with no `()` after `methname`.
- PO-2: If `property in self.options` and the object name is unqualified, the
  index text is `name (in module modname)` when a module exists, otherwise
  `name`; neither form contains callable `()`.
- PO-3: The property option takes precedence over `classmethod` and
  `staticmethod` when selecting index text.
- PO-4: If `property not in self.options`, the existing callable method,
  classmethod, and staticmethod index formats are preserved.
- PO-5: `add_target_and_index()` continues to append whatever index text
  `get_index_text()` returns and does not alter object registration semantics.

Frame conditions:

- No change to signatures, option parsing, generated node ids, domain object
  type, canonical aliases, cross-reference roles, or no-index behavior.

## Adequacy

The formal claims model only the branch behavior and index-text shape relevant
to the issue. This abstraction is property-complete for the defect because a
passing case maps to a `property*` constructor whose `hasCallableParens` value is
`false`, while the old failing behavior maps to method-shaped text whose
`hasCallableParens` value is `true`.
