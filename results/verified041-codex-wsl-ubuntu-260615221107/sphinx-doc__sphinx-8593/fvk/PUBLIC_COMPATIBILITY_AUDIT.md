# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed public surface

No public function signature, directive option, event name, return type, or storage format was changed.

## Public callsites and overrides

* `Documenter.filter_members()` is an internal method but may be overridden by extensions. The patch changes only local metadata selection inside the existing method body; it does not alter the method signature, yielded tuple shape, event emission, or option names.
* `autodoc-skip-member` event behavior remains after the keep/skip computation, so user overrides still have final say.
* `ModuleAnalyzer.attr_docs` format remains unchanged.
* `get_module_members()` output shape remains unchanged.

## Compatibility verdict

No compatibility blocker. The change is behavior-only for the intended visibility case and preserves public extension interfaces.
