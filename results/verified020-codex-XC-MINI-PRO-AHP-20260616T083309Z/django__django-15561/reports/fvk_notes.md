# FVK Notes

Status: constructed, not machine-checked. I did not run tests, Python, or K
tooling.

## Decisions and Traceability

### Kept V1's backend-specific behavior

V1's central behavior is correct under the intent spec: SQLite must treat
choices-only `AlterField` changes as no-ops, while the base editor must not
ignore `choices` globally.

Trace:

* `fvk/FINDINGS.md` F1 identifies the original SQLite table-remake behavior as
  the bug and records the expected no-op behavior.
* `fvk/FINDINGS.md` F3 rejects the global `choices` ignore because it would
  violate the public compatibility concern for enum-like fields.
* `fvk/PROOF_OBLIGATIONS.md` PO4 and PO5 encode the paired behavior: base still
  alters for choices-only differences, SQLite does not.

### Revised V1's hook name

I changed V1's `non_database_attrs` class attribute to the private,
method-specific `_field_should_be_altered_non_database_attrs`.

Changed files:

* `repo/django/db/backends/base/schema.py`
* `repo/django/db/backends/sqlite3/schema.py`

Reason:

* `fvk/FINDINGS.md` F2 flags V1's public-looking `non_database_attrs` as a
  compatibility smell because backend subclasses could define or inspect the
  same name for another purpose.
* `fvk/PROOF_OBLIGATIONS.md` PO8 requires preserving public compatibility and
  avoiding unnecessary public hook surface.

The revised name preserves the same comparison behavior while narrowing the
extension point to the private method that consumes it.

### Left the base ignored set unchanged

The base ignored-attribute tuple intentionally excludes `choices`.

Trace:

* `fvk/FINDINGS.md` F3 explains why adding `choices` globally is rejected.
* `fvk/PROOF_OBLIGATIONS.md` PO2 requires the base ignored set to remain the
  previous set.
* `fvk/PROOF_OBLIGATIONS.md` PO4 requires choices-only differences to remain
  alteration candidates under the base decision.

### Left SQLite custom-field behavior as an explicit assumption

I did not add a custom-field opt-out or a per-field choices policy.

Trace:

* `fvk/FINDINGS.md` F4 records the residual assumption: the public issue scopes
  this fix to core SQLite behavior where `choices` is metadata, and the issue
  discussion says the safe point is SQLite-specific.
* `fvk/PROOF_OBLIGATIONS.md` PO1 fixes the spec domain to this SQLite
  metadata-only choices behavior.
* `fvk/PROOF_OBLIGATIONS.md` PO6 and PO7 still require SQLite to alter for
  non-choices database-relevant changes and column changes.

### Did not modify tests or run commands

No test files were edited, and no tests or formal tools were run.

Trace:

* `fvk/FINDINGS.md` F5 records the tooling limitation.
* `fvk/PROOF_OBLIGATIONS.md` PO9 captures the task constraints.
* `fvk/PROOF.md` and `fvk/PROOF_OBLIGATIONS.md` include the exact K commands as
  artifacts only.

## Outcome

V2 is a minimal refinement of V1: the behavior remains SQLite-specific and
matches the FVK spec, while the hook introduced to share the ignored-attribute
list is now private and method-specific.
