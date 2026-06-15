# SPEC

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## Target

The audited behavior is model class construction for choice fields:

- `ModelBase.__new__()` partitions class-body attributes into ordinary
  attributes and contributable attributes, creates the class with ordinary
  attributes, then contributes fields.
- `Field.contribute_to_class()` installs `get_<field>_display()` for fields
  with `choices`.

The observable is which method an instance resolves for
`get_<field>_display()` after class construction.

## Intent Spec

I1. For a model field with `choices`, Django provides a
`get_<field>_display()` method that returns the human-readable choice label.

I2. A method named `get_<field>_display()` explicitly defined on the model class
is an override and must not be replaced by Django's generated choice-display
helper.

I3. The override rule must not depend on whether the explicit method appears
before or after the field in the class body.

I4. In the absence of an explicit direct override, Django must continue to add
the generated choice-display helper for fields with `choices`.

I5. Behavior for fields without `choices`, field descriptors, and
`_get_FIELD_display()` itself is outside the issue's requested change and must
remain framed.

I6. Whether an inherited user-defined `get_<field>_display()` method should also
block generation for a local choices field is not specified by the issue text or
local docs. This is recorded as an ambiguity, not as a required V2 code change.

## Public Evidence Ledger

E1. Source: prompt. Quote: "Cannot override get_FOO_display() in Django 2.2+."
Obligation: explicit model override must win over generated method.
Status: encoded in PO1, PO2.

E2. Source: prompt. Quote: "What I expect is that I should be able to override
this function." Obligation: replacement by the generated helper is the bug.
Status: encoded in PO2.

E3. Source: prompt example. Quote: `foo_bar = models.CharField(... choices=...)`
followed by `def get_foo_bar_display(self): return "something"`.
Obligation: field-before-method declaration order must preserve the explicit
method.
Status: encoded in PO1, PO2.

E4. Source: public hint. Quote: "Semantically order shouldn't make a
difference." Obligation: method-before-field and field-before-method class body
orders must produce the same override winner.
Status: encoded in PO1, PO2.

E5. Source: docs. Quote from `repo/docs/ref/models/instances.txt`: "For every
field that has ... choices set, the object will have a get_FOO_display()
method." Obligation: generated helper still exists when no explicit direct
override exists.
Status: encoded in PO3.

E6. Source: code. `ModelBase.__new__()` puts non-contributable attributes in
`new_attrs` before calling `super_new()`, and contributes fields afterwards.
Obligation: at `Field.contribute_to_class()` time, explicit methods from the
class body are already present in `cls.__dict__`.
Status: implementation fact used in PO1.

E7. Source: code. `Field.contribute_to_class()` previously called `setattr()` on
`get_<field>_display()` unconditionally when `choices is not None`.
Obligation: this was the mechanism that overwrote explicit methods.
Status: resolved finding F1.

E8. Source: code. Abstract base fields are copied with `copy.deepcopy(field)`
and then added to the child with `new_class.add_to_class(field.name, new_field)`.
Obligation: a generated method inherited from an abstract base must not by
itself prevent installing a generated method for the copied child field.
Status: compatibility frame in PO4.

E9. Source: public hint. Quote: `if not hasattr(cls, 'get_%s_display' %
self.name): ...`. Obligation: considered alternative guard.
Status: rejected in F3/PO4 because it is broader than the public intent and
conflicts with E8.

## Formal Model

The mini-model abstracts away database behavior and keeps only the property
under verification: the winner of the `get_<field>_display()` binding.

Definitions:

- `D`: direct class dictionary after `type.__new__()`.
- `I`: inherited attribute lookup from bases.
- `m(f)`: display method name `get_<f.name>_display`.
- `User`: an explicit user-defined method.
- `Gen(f)`: Django's generated `partialmethod(cls._get_FIELD_display,
  field=f)`.
- `Contrib(D, I, f)`: the effect of `Field.contribute_to_class()` for field
  `f`.

Formal transition:

```
If f.choices is None:
    Contrib(D, I, f).D[m(f)] == D[m(f)]       # frame condition

If f.choices is not None and m(f) in dom(D):
    Contrib(D, I, f).D[m(f)] == D[m(f)]       # direct override wins

If f.choices is not None and m(f) not in dom(D):
    Contrib(D, I, f).D[m(f)] == Gen(f)        # generated helper installed
```

The V1 code implements this transition with:

```
if self.choices is not None:
    if 'get_%s_display' % self.name not in cls.__dict__:
        setattr(cls, 'get_%s_display' % self.name,
                partialmethod(cls._get_FIELD_display, field=self))
```

## K Claim Core

These are the claims the proof obligations below discharge. They are written as
abstract reachability claims over the mini-model in
`fvk/mini-django-model-construction.k` and `fvk/django-display-spec.k`, not as a
full Python semantics.

```
claim <k> contribute(FIELD, choicesTrue, METHOD) => .K </k>
      <direct> METHOD |-> User REST </direct>
   => <direct> METHOD |-> User REST </direct>
  requires METHOD ==K displayName(FIELD)
  [all-path]

claim <k> contribute(FIELD, choicesTrue, METHOD) => .K </k>
      <direct> REST </direct>
   => <direct> METHOD |-> generated(FIELD) REST </direct>
  requires METHOD ==K displayName(FIELD)
   andBool notBool METHOD in_keys(REST)
  [all-path]

claim <k> modelBuild(ATTRS_WITH_METHOD_AND_FIELD) => contribute(FIELD, choicesTrue, METHOD) </k>
      <direct> .Map </direct>
   => <direct> METHOD |-> User FIELDNAME |-> FIELD ... </direct>
  requires METHOD ==K displayName(FIELD)
  [all-path]
```

Expected machine-check commands:

```sh
kompile fvk/mini-django-model-construction.k --backend haskell
kast --backend haskell fvk/django-display-spec.k
kprove fvk/django-display-spec.k
```

These commands were not run.
