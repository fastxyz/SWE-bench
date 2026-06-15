# PROOF_OBLIGATIONS.md

Status: constructed, not machine-checked.

## PO-1: Final registered lookup acceptance

- Intent: I-001, I-002.
- Finding trace: F-001.
- Obligation: For any related ordering path whose field prefix resolves to a prior field `F`, if the next unresolved segment `L` is the final segment and `hasLookup(F, L)` is true, `_check_ordering()` must not append `models.E015` for that path.
- V1 evidence: the patched block computes `valid` as true when `index == len(parts) - 1` and `get_lookup(part) is not None`.
- Formal claim: `FINAL-LOOKUP-VALID` and concrete reported case `REPORTED-CASE` in `ordering-check-spec.k`.
- Status: discharged by constructed proof.

## PO-2: Transform preservation

- Intent: I-004.
- Finding trace: F-003.
- Obligation: If an unresolved segment is registered as a transform on the previously resolved field, `_check_ordering()` must continue to accept it.
- V1 evidence: the patched block keeps `(get_transform and get_transform(part) is not None)` as the first validity disjunct.
- Formal claim: `TRANSFORM-STILL-VALID` in `ordering-check-spec.k`.
- Status: discharged by constructed proof.

## PO-3: Invalid unresolved segment rejection

- Intent: I-005.
- Finding trace: F-002.
- Obligation: If an unresolved segment has no prior field, or is neither a registered transform nor a final registered lookup on the prior field, `_check_ordering()` must append `models.E015`.
- V1 evidence: `valid = False` when `fld is None`; otherwise a lookup only contributes to validity under `index == len(parts) - 1`.
- Formal claim: `NONFINAL-LOOKUP-INVALID` in `ordering-check-spec.k`.
- Status: discharged by constructed proof.

## PO-4: Existing ordering preprocessing frame

- Intent: I-003.
- Finding trace: F-001.
- Obligation: Existing behavior for skipping expressions and `?`, stripping a leading `-`, and handling non-related fields is unchanged by the lookup fix.
- V1 evidence: the diff touches only the related-field unresolved-segment check; the generator filters and leading `-` stripping are outside the modified block.
- Formal treatment: frame condition in `SPEC.md`; not modeled in K because the mini semantics targets the changed related-path walker only.
- Status: confirmed by static diff review.

## PO-5: Public compatibility

- Intent: I-006.
- Finding trace: F-004.
- Obligation: The fix must not change `Model._check_ordering()`'s public/check-framework interface.
- V1 evidence: no signature, return type, error ID, or error-message template changed.
- Formal treatment: compatibility audit in `PUBLIC_COMPATIBILITY_AUDIT.md`; no K claim needed because this is an API shape property rather than path-walker behavior.
- Status: confirmed by static diff review.
