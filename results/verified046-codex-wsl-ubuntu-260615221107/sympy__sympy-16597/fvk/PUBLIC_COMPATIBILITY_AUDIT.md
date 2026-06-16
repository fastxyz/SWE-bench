# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed production symbol: `sympy.core.assumptions._assume_rules`.

Public API shape: unchanged. No function signature, class signature, return
type, virtual dispatch call, or storage format was changed.

Primary public behavior changed: old `.is_*` assumptions for rational-derived
number classes now include `finite=True`.

Affected constructor path: `Symbol.__new_stage2__` passes sanitized assumptions
to `StdFactKB`, which uses `_assume_rules` to close facts. No special-case
constructor logic was added.

Compatibility checks:

- `Symbol('x', rational=True).is_finite` should now be `True`.
- `Symbol('x', integer=True).is_finite` should now be `True`.
- `Symbol('x', even=True).is_finite` should now be `True`.
- `Symbol('x', odd=True).is_finite` should now be `True`.
- `Symbol('x').is_finite` should remain `None`.
- `Symbol('x', real=True).is_finite` should remain unchanged by this issue fix.

Rejected compatibility-sensitive broadening:

- Adding old-rule `real -> finite` is rejected for this pass because the public
  issue hint explicitly warns that old-assumption `real` is broader and that the
  broad change would probably break code.
- Updating the newer `ask(Q.*)` generated fact tables is not part of this V1
  confirmation. It is a separate API path with generated files and public tests
  that still exercise unbounded signed assumptions; changing it should be done
  as a dedicated assumptions-API cleanup with regenerated artifacts.
