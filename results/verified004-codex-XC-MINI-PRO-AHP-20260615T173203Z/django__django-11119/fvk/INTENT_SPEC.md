# Intent Spec

Status: constructed for FVK audit; not machine-checked.

## Required Behavior

1. `Engine.render_to_string()` must honor the `Engine.autoescape` attribute when it creates the `Context` used for rendering.
2. For a plain context argument, including the issue's dictionary/`None` path, the `Context` passed to `Template.render()` must have `autoescape == engine.autoescape`.
3. For a caller-supplied `Context`, `Engine.render_to_string()` must preserve that object and its existing `autoescape` setting, because the source comment records this backwards-compatible behavior.
4. Template name selection (`get_template()` versus `select_template()`) must not change the autoescape propagation behavior.
5. The public method signature and return shape of `Engine.render_to_string(template_name, context=None)` must remain unchanged.

## Domain

The audited domain is the observable behavior of `Engine.render_to_string()` for:

- `template_name` as either a single name or a list/tuple of names;
- `context` as either an existing `Context` instance or a non-`Context` value accepted by `Context(...)`, including the issue's dictionary/`None` use case;
- `engine.autoescape` as either `True` or `False`.

The model abstracts template loading success and the exact escaping algorithm. Those are outside the reported defect; the observable retained by the model is the `autoescape` flag seen by `Template.render()`.
