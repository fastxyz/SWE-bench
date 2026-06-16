# FVK Notes

## Source Decision

V1 stands unchanged. The FVK audit confirmed that removing `rolename='obj'`
from the Python-domain `variable` typed field is the correct fix.

Trace:

- `fvk/FINDINGS.md` F1 shows the root cause: a variable field label became a
  `pending_xref` and could resolve to a same-name module variable.
- `fvk/PROOF_OBLIGATIONS.md` PO2 requires that `var`/`ivar`/`cvar` labels render
  as plain labels for all same-name object inventories.
- V1 discharges PO2 because `Field.make_xref()` returns plain content when the
  field has no `rolename`.

## Alternatives Rejected

I kept the resolver unchanged.

Trace:

- `fvk/FINDINGS.md` F2 shows that resolver-only fuzzy narrowing is incomplete:
  the resolver also has a same-module fallback path.
- `fvk/PROOF_OBLIGATIONS.md` PO5 requires the fix to cover same-module and
  cross-project same-name objects.
- Removing the field-label xref at the source satisfies PO5 without changing
  explicit Python cross-reference resolution.

I did not change variable fields to `attr` links.

Trace:

- `fvk/FINDINGS.md` F2 covers the same design problem: keeping an implicit field
  label xref leaves unrelated same-name object resolution in play.
- `fvk/PROOF_OBLIGATIONS.md` PO2 requires no automatic xref for the field label,
  not just a narrower xref kind.

## Compatibility Decisions

I preserved variable type links.

Trace:

- `fvk/FINDINGS.md` F3 records the compatibility obligation for `:vartype:`.
- `fvk/PROOF_OBLIGATIONS.md` PO3 requires type names to remain eligible for
  Python type-reference generation.
- V1 leaves `typerolename='class'` unchanged.

I preserved explicit Python roles.

Trace:

- `fvk/PUBLIC_EVIDENCE_LEDGER.md` E5 says explicit roles are the user-controlled
  way to link related objects.
- `fvk/PROOF_OBLIGATIONS.md` PO4 requires explicit references to remain
  unchanged.
- V1 does not modify `PythonDomain.roles`, `PyXrefMixin`, or `find_obj()`.

## Artifact Decisions

I produced the five requested FVK artifacts and the additional adequacy/formal
core required by the FVK documentation:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-sphinx-fields.k`
- `fvk/sphinx-fields-spec.k`

Trace:

- `fvk/PROOF_OBLIGATIONS.md` PO1 covers adequacy and public intent provenance.
- `fvk/PROOF_OBLIGATIONS.md` PO6 covers the honesty gate.
- `fvk/FINDINGS.md` F4 records that tests, Python code, and K tooling were not
  executed under the benchmark constraints.

## Execution Caveat

No tests, Python code, or K tooling were run. The proof is constructed, not
machine-checked. This is intentional and is tracked by `fvk/FINDINGS.md` F4 and
`fvk/PROOF_OBLIGATIONS.md` PO6.
