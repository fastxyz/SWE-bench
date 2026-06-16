# FVK Notes

## Production Source Decision

V1 stands unchanged. The audit did not justify another source edit.

The decision traces to F2 in `fvk/FINDINGS.md`: after V1,
`Model._check_default_pk()` requires `cls._meta.pk is cls._meta.auto_field`.
That condition is false for the inherited parent-link primary key described in
F1, so the reported `models.W042` false positive is removed. This discharges
PO1 and PO4 in `fvk/PROOF_OBLIGATIONS.md`.

The decision also traces to F3: the implicit default primary key path still has
`pk.auto_created=true` and `pk is _meta.auto_field=true`, so the intended W042
case remains covered. This discharges PO2. The unchanged `pk.auto_created`
conjunct preserves explicit-primary-key behavior, discharging PO3, and the
unchanged override checks preserve the setting/app suppression behavior,
discharging PO5.

## FVK Artifact Decisions

I added `fvk/SPEC.md` to record the intent ledger, formal abstraction, adequacy
audit, and compatibility audit. This supports PO1 through PO5 by tying each
formal condition to public issue text, public in-repo tests, or source metadata
evidence.

I added `fvk/FINDINGS.md` to record the pre-V1 bug (F1), the V1 confirmation
(F2 and F3), and the honesty limitation that the proof is constructed but not
machine-checked (F4). F4 exists to satisfy PO6.

I added `fvk/PROOF_OBLIGATIONS.md` to make the required cases explicit:
inherited parent links, implicit defaults, explicit primary keys, metadata
discriminator validity, API compatibility, and the no-execution honesty gate.

I added `fvk/PROOF.md`, `fvk/mini-default-pk.k`, and
`fvk/default-pk-spec.k` to provide the constructed formal core and the exact
commands that would be run in an environment where K tooling is permitted.
Those commands were intentionally not executed, per F4 and PO6.

I added `fvk/ITERATION_GUIDANCE.md` to state that no further source change is
recommended and that future test work should add a regression test for a child
model inheriting a concrete parent's manually specified primary key. Tests were
not edited because this task forbids modifying test files.

## Alternatives Rechecked

Suppressing W042 for all models with concrete parents remains rejected. It would
satisfy F1 but is broader than PO1 and does not use the precise discriminator
required by PO4.

Checking only the primary key's field type remains rejected. `cls._meta.pk is
cls._meta.auto_field` is narrower and directly follows from the metadata
producer paths in PO4.
