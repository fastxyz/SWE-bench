# FVK Notes

## Source decision

No additional source edit was made after V1. The decision to keep V1 unchanged
is justified by F-001 in `fvk/FINDINGS.md`: the reported failure is exactly the
template callable gate calling an intermediate choices enum class. PO-001
through PO-003 in `fvk/PROOF_OBLIGATIONS.md` cover the required repair: mark
every `ChoicesMeta`-created class, let the existing resolver preserve marked
callables, and then continue dotted lookup to the enum member.

## Resolver decision

I did not change `repo/django/template/base.py`. F-002 records that the resolver
already has the intended public behavior for values with
`do_not_call_in_templates == True`; PO-002 proves the fix only needs to supply
that marker on choices enum classes. Editing the resolver would broaden the
change beyond the issue and would add compatibility risk without a public
obligation.

## Enum implementation decision

I kept the V1 placement in `ChoicesMeta.__new__()` rather than moving the
assignment into the `Choices` class body. F-003 identifies the hazard: enum
class-body assignments can enter the member namespace. PO-004 requires the
marker to leave members and choices metadata unchanged, which V1 satisfies by
assigning the attribute after `EnumMeta.__new__()` has created the class.

## Compatibility decision

No API compatibility repair was needed. PO-005 and
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` show that V1 changes no public signatures,
exports, resolver branch ordering, or choices metadata APIs.

## Verification caveat

The FVK proof is constructed, not machine-checked. The exact K commands are
recorded in `fvk/PROOF.md`, but they were not run because this task forbids
running K tooling, Python, or tests.
