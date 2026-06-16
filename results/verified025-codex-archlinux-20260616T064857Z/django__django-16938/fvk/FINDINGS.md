# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-001: Pre-fix primary-key m2m serialization can raise FieldError

Classification: code bug in the pre-V1 implementation; resolved by V1.

Input: an auto-created many-to-many relation to a model whose default manager
returns a queryset with `select_related("master")`, with no natural-key
serialization.

Observed before V1: the serializer applied `only("pk")` while inherited
`select_related("master")` was still present, reaching
`select_related_descend()` and raising `FieldError`.

Expected: serialization should produce the related primary key reference list.

Evidence: E1, E2, E4, and PO-1.

Resolution: V1 calls `select_related(None)` before `only("pk")`, so the selected
relation set is empty when the primary-key load mask is applied.

## F-002: XML has the same duplicated primary-key m2m query path

Classification: completeness issue for the serializer family; resolved by V1.

Input: the same m2m/custom-manager setup serialized through XML.

Observed before V1: XML's separate `handle_m2m_field()` implementation also used
`only("pk")` without clearing inherited `select_related`.

Expected: XML should serialize m2m primary-key references without the same
`FieldError`.

Evidence: E5 and PO-4.

Resolution: V1 applies the same `select_related(None).only("pk")` sequence to
XML.

## F-003: The public hint is ambiguous about the clearing API

Classification: spec ambiguity resolved by source evidence.

Input: choosing between no-argument `select_related()` and
`select_related(None)`.

Observed in source: `select_related(None)` clears the list; no-argument
`select_related()` enables unrestricted selection.

Expected: the fix must clear inherited selection.

Evidence: E3, E6, and PO-3.

Resolution: V1 uses `select_related(None)`. No source change is needed.

## F-004: Natural-key serialization is intentionally unchanged

Classification: frame condition; no code bug found.

Input: m2m serialization with `use_natural_foreign_keys` and a related model
that defines `natural_key()`.

Observed in source: the natural-key branch uses the full related object and does
not apply `only("pk")`.

Expected: manager-level `select_related()` may remain useful because
`natural_key()` can need non-primary-key fields.

Evidence: PO-5.

Resolution: V1 leaves this branch unchanged.

## F-005: Proof remains constructed, not machine-checked

Classification: proof capability boundary, not a code bug.

Input: the FVK claims in `fvk/serializer-m2m-spec.k`.

Observed: K tooling was not run by instruction.

Expected: test removal or machine-verified confidence requires running the
emitted `kompile`/`kprove` commands in an environment that has K installed.

Evidence: FVK instructions and PO-7.

Resolution: keep all tests; add or rely on tests only as conventional coverage
until the proof is machine-checked.

## Summary

No finding requires a source change beyond V1. The audit confirms V1 against the
specified intent and records the proof boundary honestly.
