# PROOF OBLIGATIONS

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## PO1: Class-Body Methods Are Present Before Field Contribution

Claim:

For any model class body containing an ordinary method `m` and a field `f`,
`ModelBase.__new__()` creates `new_class` with `m in new_class.__dict__` before
calling `new_class.add_to_class(f.name, f)`.

Evidence:

- `ModelBase.__new__()` sends objects without `contribute_to_class()` to
  `new_attrs`.
- Fields are collected in `contributable_attrs`.
- `new_class = super_new(cls, name, bases, new_attrs, **kwargs)` runs before
  `for obj_name, obj in contributable_attrs.items(): new_class.add_to_class(...)`.

Why it matters:

This discharges the order-insensitivity obligation. Whether the method is
written before or after the field in the class body, it is in `cls.__dict__`
when `Field.contribute_to_class()` runs.

Findings traced: F1, F2.

## PO2: Direct Explicit Display Override Is Preserved

Claim:

If `self.choices is not None` and `display_name = 'get_%s_display' % self.name`
is already in `cls.__dict__`, `Field.contribute_to_class()` does not assign a
generated display method to that name.

Discharge:

The V1 branch is:

```
if self.choices is not None:
    if 'get_%s_display' % self.name not in cls.__dict__:
        setattr(...)
```

Given `display_name in cls.__dict__`, the inner condition is false, so no
`setattr()` occurs. The direct method binding is framed unchanged.

Findings traced: F1, F2.

## PO3: Generated Display Method Is Still Installed When No Direct Override Exists

Claim:

If `self.choices is not None` and `display_name not in cls.__dict__`, then after
`Field.contribute_to_class()` the class has
`display_name = partialmethod(cls._get_FIELD_display, field=self)`.

Discharge:

Given `display_name not in cls.__dict__`, the inner condition is true and the
same `setattr()` used before V1 runs. This preserves the documented default
behavior that choice fields have `get_FOO_display()`.

Findings traced: F3.

## PO4: `cls.__dict__` Guard Preserves Abstract-Field Generated Binding Refresh

Claim:

For a child class inheriting a generated display method from an abstract base
but receiving a copied choices field through `copy.deepcopy(field)` and
`new_class.add_to_class(field.name, new_field)`, V1 installs a generated method
for the child field unless the child class defines a direct method with the
same name.

Discharge:

An inherited generated method is visible through attribute lookup but is not in
the child class's own `__dict__`. Therefore V1's guard treats the display name
as absent and installs `partialmethod(cls._get_FIELD_display, field=new_field)`.

This is the side-by-side rejection of `hasattr()`:

```
candidate A: method_name not in cls.__dict__
  inherited generated method only -> true -> install child generated method

candidate B: not hasattr(cls, method_name)
  inherited generated method only -> false -> skip child generated method
```

Candidate B fails the compatibility frame from the abstract-field copy path.

Findings traced: F3.

## PO5: Non-Choice Fields and Existing Descriptor Logic Are Framed

Claim:

For `self.choices is None`, V1 does not change display-method generation
behavior, field descriptor assignment, `_meta.add_field()`, or
`_get_FIELD_display()`.

Discharge:

The edit is syntactically inside the `if self.choices is not None:` branch and
only guards the display-helper `setattr()`. The preceding field registration
and descriptor block are unchanged. `_get_FIELD_display()` is not edited.

Findings traced: F5.

## PO6: Inherited User Method Semantics Are Underspecified

Claim:

The public evidence does not force a code change that preserves inherited
user-defined `get_<field>_display()` methods for newly contributed local choices
fields.

Discharge:

The issue example and declaration-order discussion both concern methods defined
directly in the class body being constructed. Local docs only state that Django
adds `get_FOO_display()` for choices fields. No public evidence in the allowed
inputs states that an inherited user method must block local field generation.

This obligation prevents expanding the fix beyond the supported spec. It also
records the UltimatePowers-style question for a future intent pass: "Should an
inherited user-defined `get_FOO_display()` method block generation for a local
choices field?"

Findings traced: F4.

## PO7: Honesty Gate and Residual Risk

Claim:

The proof is a constructed partial-correctness argument over the abstract
mini-model and is not machine-checked.

Discharge:

No `kompile`, `kast`, `kprove`, tests, Python snippets, or Django runtime code
were executed. The proof covers the class-construction winner rule only. It
does not prove termination, app-registry integration, or database behavior.

Findings traced: F5.
