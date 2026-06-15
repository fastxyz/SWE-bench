# Intent Spec

Status: constructed from public evidence; no tests, Python, or K tooling run.

## Required behavior

1. Django model enumeration types must be usable in templates.
2. A dotted template lookup such as `YearInSchool.FRESHMAN` must not call the
   intermediate `YearInSchool` enum class with zero arguments.
3. The enum class must remain available for the following attribute lookup so
   the member `FRESHMAN` can be resolved normally.
4. The fix should use Django's existing `do_not_call_in_templates` opt-out hook.
5. The behavior applies to the Django `Choices` family: `Choices`,
   `IntegerChoices`, `TextChoices`, custom `Choices` subclasses, and classes
   created through the enum functional API.

## Frame conditions

1. Existing template behavior for non-choices callables is unchanged.
2. Existing choices enum behavior is unchanged except for the added template
   opt-out marker: enum members, member values, labels, `choices`, `names`,
   `values`, `labels`, `__str__`, containment, and uniqueness checks retain
   their prior behavior.
3. Public API signatures and exports are unchanged.

## Out of scope

1. Termination is not separately proved. The audited path is finite lookup and
   class creation without loops.
2. The full Django template engine is not modeled. The proof models only the
   callable gate and dotted lookup behavior required by the issue.
