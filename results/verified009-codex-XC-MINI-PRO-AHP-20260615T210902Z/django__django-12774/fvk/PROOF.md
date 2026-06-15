# FVK Proof

Status: constructed, not machine-checked.

## What Is Proved

For the validation branch of `QuerySet.in_bulk()`:

1. `field_name == 'pk'` is accepted.
2. `field.unique` is accepted.
3. A non-unique field is accepted when a constraint in
   `opts.total_unique_constraints` has exactly one field identifier matching
   the resolved field's `name` or `attname`.
4. Otherwise the existing `ValueError` branch is taken.
5. Once validation accepts, all query evaluation and dictionary construction
   behavior is framed as unchanged from the pre-existing implementation.

This is a partial-correctness proof over the modeled validation decision. There
are no loops in the changed code path.

## Formal Core

The proof uses:

- `fvk/mini-inbulk.k`: a minimal semantics for `validate(fieldName, field,
  constraints)`.
- `fvk/in-bulk-spec.k`: K claims for accepted and rejected cases.

The model is intentionally narrow but property-complete for the defect: it
distinguishes a passing instance, such as `uc("slug", true)`, from failing
instances, such as `uc("slug", false)` for conditional/composite constraints
or a constraint on a different field.

## Symbolic Proof Sketch

Case 1, primary key:

`validate("pk", field(NAME, ATT, UNIQUE), CS)` rewrites directly to `allow`.
This discharges SPEC-ACCEPT-PK and PO4.

Case 2, `unique=True`:

For `FIELDNAME != "pk"`, the field rule with `unique == true` rewrites to
`allow` independently of constraints. This preserves pre-existing behavior and
discharges SPEC-ACCEPT-FIELD-UNIQUE and PO4.

Case 3, total single-field `UniqueConstraint`:

For `FIELDNAME != "pk"` and `unique == false`, the constraints list is scanned.
If it contains `uc(ID, true)` with `ID == NAME` or `ID == ATT`, the helper
`singleTotalMatches(NAME, ATT, CS)` rewrites to `true`, and validation rewrites
to `allow`. This discharges SPEC-ACCEPT-UNIQUE-CONSTRAINT, SPEC-ACCEPT-ATTNAME,
PO3, and PO5.

Case 4, non-qualifying constraints:

For `FIELDNAME != "pk"` and `unique == false`, if the constraint list is empty
or contains only `uc(ID, false)` or identifiers different from both `NAME` and
`ATT`, `singleTotalMatches(NAME, ATT, CS)` rewrites to `false`, and validation
rewrites to `reject`. This discharges SPEC-REJECT-NON-UNIQUE,
SPEC-REJECT-NON-SINGLE, SPEC-REJECT-CONDITIONAL, and PO6.

## Proof-Derived Findings

The proof construction surfaced one V1 completeness gap: V1's explanation
relied on resolved `field.name`, but Django's local field validation accepts
both `field.name` and `field.attname` as field identifiers. V2 changes the code
to compare both. See finding F2 and obligation PO3.

No proof obligation requires accepting composite or conditional constraints.
Accepting them would violate the single-key dictionary mapping obligation. See
findings F3 and F4.

## Machine-Check Commands

These commands are recorded for a later environment with K installed. They were
not executed in this benchmark session.

```sh
kompile fvk/mini-inbulk.k --backend haskell
kast --backend haskell fvk/in-bulk-spec.k
kprove fvk/in-bulk-spec.k
```

Expected machine-check result after any needed syntax adjustment for the local
K version: `#Top` for all claims.

## Test Recommendation

Do not remove tests in this session. If the K claims are machine-checked later,
unit tests that assert acceptance of a single-field total `UniqueConstraint`
would be subsumed by PO5. Tests for batching, database integration, query
evaluation, and non-unique rejection should be kept because they cover behavior
outside the narrow validation proof or integration with the database.
