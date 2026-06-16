# Public Compatibility Audit

Status: constructed for FVK audit; not machine-checked.

## Changed Public Symbol

- `django.template.defaultfilters.add(value, arg)`

## Compatibility Checks

- Signature: unchanged.
- Template filter registration: unchanged (`@register.filter(is_safe=False)`).
- Return-shape contract: unchanged except for the issue-required case where a
  text lazy proxy now behaves like its resolved string instead of causing the
  empty-string fallback.
- Public callsites: no caller changes are required because inputs, arguments,
  and return conventions are unchanged.
- Subclasses/overrides: not applicable; `add` is a module-level function.
- Import compatibility: adding `Promise` to `defaultfilters.py` is internal to
  the module and does not alter public API.
- Tests: no test files were modified, per task constraints.

Result: pass. The V1 source change is local and backward-compatible for the
documented public surface.

