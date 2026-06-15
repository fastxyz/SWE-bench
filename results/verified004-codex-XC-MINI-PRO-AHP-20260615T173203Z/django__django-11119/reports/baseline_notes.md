# Baseline Notes

## Root Cause

`Engine.render_to_string()` creates a new `Context` for plain dictionaries and
`None` without passing the engine's `autoescape` setting. Since `Context`
defaults `autoescape` to `True`, direct calls to `Engine.render_to_string()` on
an engine configured with `autoescape=False` still render with escaping enabled.

## Changed Files

`repo/django/template/engine.py`

- Updated `Engine.render_to_string()` so newly created `Context` instances use
  `autoescape=self.autoescape`.
- Left the existing `Context` instance path unchanged so callers that explicitly
  provide a `Context` keep controlling its rendering options.

## Assumptions and Alternatives

- Assumed the engine-level `autoescape` option should apply only when
  `Engine.render_to_string()` is responsible for constructing the context,
  matching the backend render path that already passes the engine setting into
  context creation.
- Considered changing `Context`'s default or modifying template rendering to
  consult `template.engine.autoescape`, but rejected both because they would
  affect broader direct-template behavior outside the reported
  `Engine.render_to_string()` issue.
- Considered rewrapping existing `Context` objects with the engine setting, but
  rejected it because the method intentionally preserves callers' existing
  `Context` instances.
