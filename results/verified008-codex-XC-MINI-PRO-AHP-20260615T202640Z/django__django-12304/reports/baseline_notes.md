# Baseline Notes

## Root cause

Django template variable resolution calls callable values unless they expose
`do_not_call_in_templates`. `Choices` subclasses are enum classes, so they are
callable constructors. When a template resolves `YearInSchool.FRESHMAN`, the
intermediate `YearInSchool` value is callable and the resolver attempts to call
it with no arguments, which fails before the `FRESHMAN` member can be read.

## Changed files

- `repo/django/db/models/enums.py`: `ChoicesMeta.__new__()` now assigns
  `do_not_call_in_templates = True` to each created choices enum class. This
  lets the existing template resolver keep the enum class intact instead of
  calling it, so member lookups such as `YearInSchool.FRESHMAN` can proceed.

## Assumptions and alternatives considered

- I assumed the intended behavior is for all `models.Choices` classes,
  including `IntegerChoices`, `TextChoices`, functional-API choices, and custom
  `Choices` subclasses, to be usable from templates without being called.
- I rejected adding `do_not_call_in_templates = True` directly in the `Choices`
  class body because plain assignments in an `Enum` class body can become enum
  members. Assigning the attribute after `EnumMeta` creates the class avoids
  changing the enum member set.
- I rejected changing the template resolver because it already has the correct
  opt-out hook and the issue is specific to choices enum classes missing that
  marker.
