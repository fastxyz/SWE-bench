# FVK Notes

Status: V1 confirmed; no source files were edited during the FVK pass.

## Decisions

The V1 source change in `repo/django/contrib/admin/options.py` stands because
the audit found it satisfies the reported intent. `fvk/FINDINGS.md` F1 and
`fvk/PROOF_OBLIGATIONS.md` PO3 show the reported lookup
`restaurant__place__country` is accepted through the actual resolved field-path
candidate, which is the behavior required by the issue and the admin docs.

The `field_parts` candidate is kept. F1/PO3 show it is the mechanism that
prevents the relational primary-key field `place` from disappearing when the
configured `list_filter` path is compared.

The trailing target-field stripping loop is kept. F2/PO4 show that admin
related filters can generate keys such as
`restaurant__place__country__id__exact`, and those keys must still map back to
the configured `restaurant__place__country` filter path.

The original collapsed-path behavior is kept. F3/PO2 and F3/PO4 show that a
direct relation filter such as `restaurant` may legitimately produce a lookup
using the related target field, e.g. `restaurant__place__exact`, and V1
continues to allow it.

No narrowing change was made to reject all relational target-field aliases.
That alternative would satisfy F1 but would violate the compatibility
obligation captured in F2 and PO4.

No broadening change was made beyond V1. F4/PO5 shows the current candidate set
still rejects a real field beyond the configured filter path, such as
`restaurant__place__country__name`, unless that extended path is also
configured.

No tests or source test files were changed. F5/PO6 records that verification is
constructed, not machine-checked, and this environment forbids running tests,
Python, or K tooling.

## Artifacts

The FVK artifacts were written under `fvk/`:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`
- `mini-admin-lookup.k`
- `lookup-allowed-spec.k`

The `.k` files are lightweight constructed artifacts for the lookup-normalizer
abstraction. The commands to check them are recorded in `fvk/PROOF.md`, but
they were not executed.
