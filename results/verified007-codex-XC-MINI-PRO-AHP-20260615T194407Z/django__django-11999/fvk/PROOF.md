# PROOF

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## What Is Proved

For the modeled class-construction path:

1. A `get_<field>_display()` method explicitly present in the model class body
   is present in `cls.__dict__` before the choices field contributes.
2. V1 preserves that direct method instead of overwriting it with Django's
   generated `partialmethod`.
3. If no direct method exists, V1 still installs the generated
   `get_<field>_display()` helper for fields with `choices`.
4. The `cls.__dict__` guard avoids the overbroad `hasattr()` behavior that would
   skip generation because of inherited generated methods from abstract bases.

## Symbolic Proof Sketch

Let:

- `f` be a field with `f.choices is not None`;
- `d = 'get_%s_display' % f.name`;
- `User` be a user-defined method;
- `Gen(f) = partialmethod(cls._get_FIELD_display, field=f)`;
- `D` be `cls.__dict__` at the entry of `Field.contribute_to_class()`.

### Direct Override Case

Precondition:

```
d in dom(D)
D[d] = User
f.choices is not None
```

V1 executes the outer choices branch. The inner condition is:

```
d not in cls.__dict__
```

By the precondition this is false. Therefore the `setattr(cls, d, Gen(f))`
transition is not taken. All other edited-state components relevant to `d` are
framed, so the postcondition is:

```
D'[d] = User
```

This proves PO2.

### Declaration-Order Case

Consider either class body order:

```
field f; method d
method d; field f
```

`ModelBase.__new__()` partitions by `_has_contribute_to_class()` rather than
using the original order as the final contribution order. The method has no
`contribute_to_class()` and is inserted into `new_attrs`; the field has
`contribute_to_class()` and is inserted into `contributable_attrs`.

`type.__new__()` runs with `new_attrs`, so the created class has `d in
cls.__dict__`. Only afterwards does `new_class.add_to_class(field_name, f)` call
`Field.contribute_to_class()`.

Both syntactic orders reduce to the Direct Override Case above. This proves
PO1 and F2.

### Generated Helper Case

Precondition:

```
d not in dom(D)
f.choices is not None
```

The outer choices branch is taken and the inner guard is true. V1 executes:

```
setattr(cls, d, partialmethod(cls._get_FIELD_display, field=f))
```

Postcondition:

```
D'[d] = Gen(f)
```

This is the same generated binding behavior Django had before V1 for classes
without an explicit direct override. This proves PO3.

### Abstract-Base Generated Method Case

Precondition:

```
d not in child.__dict__
d is visible through an abstract base class
base.__dict__[d] = Gen(base_field)
child_field = deepcopy(base_field)
```

With V1, `d not in child.__dict__` is true, so child field contribution installs:

```
child.__dict__[d] = Gen(child_field)
```

With the proposed `hasattr()` alternative, `hasattr(child, d)` would be true
because inherited lookup finds `base.__dict__[d]`; generation would be skipped.
That alternative does not preserve the field-copy contribution shape described
by `ModelBase.__new__()`.

This proves PO4 and justifies keeping V1's narrower guard.

## Adequacy Check

The formal claims are adequate for the public issue because they distinguish
the failing and passing states on the exact observable under dispute:

- failing state: direct `User` method exists before field contribution but final
  class binding is `Gen(f)`;
- passing state: direct `User` method exists before field contribution and final
  class binding remains `User`.

The mini-model intentionally does not model database I/O, app registration, or
full descriptor binding because those are not contributors to the reported
winner-rule regression.

The inherited-user-method scenario is not proved as correct; it is recorded as
F4/PO6 because public intent is insufficient to choose that compatibility rule.

## Machine-Check Commands

The proof is constructed only. The abstract K artifacts are
`fvk/mini-django-model-construction.k` and `fvk/django-display-spec.k`. In a
K-capable environment, the intended commands are:

```sh
kompile fvk/mini-django-model-construction.k --backend haskell
kast --backend haskell fvk/django-display-spec.k
kprove fvk/django-display-spec.k
```

Expected result after successful machine checking: `#Top`.

## Test Guidance

No tests were modified or run. Existing and future tests should be kept until
both ordinary Django tests and any K proof are actually executed.

Tests suggested by the proof obligations:

- explicit `get_<field>_display()` declared after a choices field;
- explicit `get_<field>_display()` declared before a choices field;
- no explicit method, generated `get_<field>_display()` still returns the
  human-readable choice;
- abstract-base choices field copied to a child still gets a generated method
  bound to the child field;
- inherited user-defined `get_<field>_display()` behavior, if project maintainers
  clarify that it should be supported.
