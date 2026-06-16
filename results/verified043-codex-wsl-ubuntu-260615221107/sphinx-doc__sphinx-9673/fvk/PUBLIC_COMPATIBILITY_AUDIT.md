# Public Compatibility Audit

Status: constructed for FVK audit, not machine-checked.

## Changed Symbol

`sphinx.ext.autodoc.typehints.augment_descriptions_with_types(node, annotations)`

## Compatibility Checks

- Function signature: unchanged.
- Return value: unchanged (`None`, mutates field list as before).
- Public config names: unchanged.
- Sphinx event hooks: unchanged.
- Napoleon output: unchanged.
- Python-domain field names: unchanged; V1 aligns autodoc with the existing
  `names=('returns', 'return')` domain definition.
- Public callsites: `merge_typehints()` still calls the same function with the
  same arguments only for the `"documented"` branch.
- Subclass/override risk: none found for this module-level helper.

## Result

No compatibility blocker. The behavior change is additive for a field spelling
already accepted by the Python domain and already emitted by Napoleon.
