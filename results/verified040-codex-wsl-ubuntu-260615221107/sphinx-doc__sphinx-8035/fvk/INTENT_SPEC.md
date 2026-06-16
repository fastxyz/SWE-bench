# Intent Spec

Status: constructed from public evidence only; not machine-checked.

## Required Behavior

1. `:private-members:` must accept an optional comma-separated argument list of private member names.
2. A bare `:private-members:` option, and a default option value of `None` or `True`, must continue to mean "include all eligible private members" when member generation is active.
3. `:private-members: _one, _two` must include `_one` and `_two` when they are eligible private members, and must not include other private members solely because `private-members` is present.
4. The list syntax should follow `:members:`: comma-separated names with surrounding whitespace ignored and empty entries ignored.
5. Explicit private names should behave like other explicit member requests. They may be added to the explicit `members` list so that they can be documented without requiring the user to enumerate the enclosing class separately.
6. Existing autodoc filters still apply: `exclude-members` and mocked objects are skipped, undocumented members require `undoc-members` unless source attribute documentation is present, and user `autodoc-skip-member` callbacks may override the decision.
7. Public member behavior, special member behavior, `members` behavior, `inherited-members`, `ignore-module-all`, and public method signatures must remain compatible.
8. Public documentation should describe that `private-members` is no longer only a flag and can take an explicit list.

## Domain

The in-scope option values are the documented autodoc directive/default-option values: absent option, bare option (`None`), `True`, or a comma-separated string. Other non-string truthy values were not documented as valid option values and are outside this intent domain.

The in-scope member decisions are autodoc member filtering decisions for module and class documenters where a member has a name, private/public classification, documentation status, source-attribute documentation status, exclude/mock status, and optional user skip override.

## Out Of Scope

This audit does not change the semantics of `__all__`, import filtering, inherited member ordering, or user skip callbacks. Those behaviors are preserved unless they conflict with the selected-private-member obligation.
