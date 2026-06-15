# Public Compatibility Audit

Status: constructed audit; no code execution performed.

## Changed Public Symbol

`django.template.engine.Engine.render_to_string(template_name, context=None)`

- Signature: unchanged.
- Return protocol: unchanged; still returns `t.render(...)`.
- Template selection behavior: unchanged; still uses `select_template()` for list/tuple names and `get_template()` otherwise.
- Existing `Context` behavior: unchanged; still renders the supplied `Context` without rewrapping.

## Internal Constructor Call

`Context(context)` became `Context(context, autoescape=self.autoescape)` in V1.

- `Context.__init__()` already declares `autoescape=True`, so the keyword is supported by the existing API.
- This does not add a virtual dispatch call or change an override contract.

## Callsite/Override Scan

Search over `repo/django` found no direct public callsites of `Engine.render_to_string()` other than the method definition itself. The higher-level `django.template.loader.render_to_string()` path already uses backend `Template.render()`, which passes `autoescape=self.backend.engine.autoescape` through `make_context()`.

Compatibility finding: no unhandled callsite, subclass override, signature, or producer/consumer issue was found.
