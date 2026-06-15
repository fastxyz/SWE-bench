# Baseline Notes

## Root Cause

`Field.contribute_to_class()` unconditionally installed a generated
`get_<field>_display()` partial method whenever a field had `choices`.

In Django 2.2+, `ModelBase.__new__()` first creates the model class with
non-contributable attributes, including user-defined methods, and only then
adds fields through `contribute_to_class()`. Because field contribution happened
after the class method was already present, the generated display method replaced
an explicit `get_<field>_display()` method defined on the model.

## Changed Files

`repo/django/db/models/fields/__init__.py`

The `choices` branch in `Field.contribute_to_class()` now checks whether the
target model class defines `get_<field>_display()` directly before installing
the generated method. If the method is present in `cls.__dict__`, it is treated
as an explicit model override and left intact. Otherwise, Django keeps adding
the generated display method as before.

## Assumptions and Alternatives

The fix assumes that an explicit method on the concrete class being constructed
should take precedence over Django's generated choice display helper, regardless
of whether the method appears before or after the field in the class body.

I considered guarding with `hasattr(cls, method_name)`, as suggested in the
issue discussion. I rejected that because it would also treat inherited methods
as overrides. In particular, generated display methods inherited from abstract
base models could prevent subclasses from receiving a generated method bound to
their own copied field instance. Checking `cls.__dict__` is narrower: it fixes
the explicit override regression while preserving the existing behavior for
inherited/generated display methods.

No tests were run, per the task instruction that this session has no execution
environment and tests must not be executed.
