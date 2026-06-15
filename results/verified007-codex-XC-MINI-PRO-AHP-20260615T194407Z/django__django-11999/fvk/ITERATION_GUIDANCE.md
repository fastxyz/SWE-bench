# ITERATION GUIDANCE

Status: constructed, not machine-checked. No tests, Python, or K tooling were
executed.

## V2 Decision

Keep V1 unchanged.

The FVK audit confirms that V1 discharges the public issue's required behavior:
an explicit `get_<field>_display()` method defined directly on the model class
is preserved for choice fields, independent of declaration order.

## Do Not Change to `hasattr()`

The public issue includes a suggested `hasattr()` guard, but PO4/F3 show that it
is too broad for Django's construction path. It can treat inherited generated
methods from abstract base classes as blockers and skip generating a helper for
a copied child field.

The narrower `cls.__dict__` guard fixes the explicit direct override regression
without changing inherited generated-method behavior.

## Deferred Clarification

F4/PO6 identify one under-specified case:

```
class Base:
    def get_foo_display(self):
        ...

class Child(Base, models.Model):
    foo = models.CharField(choices=...)
```

The allowed public evidence does not say whether the inherited user method
should block local choice-display generation. Do not expand the production fix
for this case without maintainer intent or public API documentation.

UltimatePowers-style question:

Should an inherited user-defined `get_<field>_display()` method be treated as a
user override for a local choices field, or should only methods defined directly
on the model class being constructed block generation?

## Recommended Tests To Add Outside This Task

Do not modify tests in this benchmark task. In a normal development pass, add or
keep tests for:

- direct override after field declaration;
- direct override before field declaration;
- generated method still installed when no direct override exists;
- abstract-base copied choices field still gets a generated method for the child
  field;
- inherited user-method behavior after maintainers clarify the intended rule.

## Machine-Check Follow-Up

The proof artifacts are not machine-checked. In an environment with K available,
check the abstract K claims with:

```sh
kompile fvk/mini-django-model-construction.k --backend haskell
kast --backend haskell fvk/django-display-spec.k
kprove fvk/django-display-spec.k
```

Keep all tests until both the K proof and ordinary Django test suite are run.
