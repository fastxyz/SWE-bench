# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Public Surfaces

| Surface | Change | Compatibility result |
| --- | --- | --- |
| `automodule` option `private-members` | Converter changed from flag-only to `members_option`. | Compatible for documented values: bare/`None`/`True` still mean all private members; string values now gain requested behavior. |
| `autoclass` option `private-members` | Converter changed from flag-only to `members_option`. | Compatible for documented values: bare/`None`/`True` still mean all private members; string values now gain requested behavior. |
| `autodoc_default_options['private-members']` | String values now select private names. | Compatible with documented `None`/`True`; expands documented default-options value support. |
| `merge_special_members_option()` | Now delegates to shared merge helper and copies selector lists when seeding `members`. | Behavior preserved; copying avoids aliasing and does not change visible selected names. |
| `merge_private_members_option()` | New internal helper. | No public callsite compatibility issue; called only by module/class documenter initialization. |
| `doc/usage/extensions/autodoc.rst` | Documents explicit `private-members` arguments and default-options example. | Aligns public docs with new behavior. |

## Callsite And Override Audit

No public method signature changed. No virtual dispatch call gained a new argument. `ModuleDocumenter.__init__` and `ClassDocumenter.__init__` still accept `*args` and now call one additional internal helper. Existing subclasses are unaffected because the helper mutates the same `Options` object shape already used by `special-members`.

## Boundary

Previously undocumented non-string truthy values other than `True` for `private-members` may now be invalid because `members_option` expects a string list. That is outside the documented domain in `autodoc_default_options`, which names `None`, `True`, and string option values.
