# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Empty conversion suppresses numeric deprecation

- Formal claim: `CONVERT-EMPTY-VACUOUS-NUMERIC`.
- Precondition: `N == 0`, valid category unit, `UpdateAccepts == true`,
  `AllNumlike == true` by possible vacuity.
- Required postcondition: status `ok`, result size `0`, warnings list empty.
- Evidence: E1-E5.
- Source line discharged by V1: `if values.size and is_numlike:`.

## PO-2: Non-empty numeric conversion preserves deprecation path

- Formal claim: `CONVERT-NONEMPTY-NUMERIC`.
- Precondition: `N > 0`, `AllNumlike == true`.
- Required postcondition: status `ok`, result size `N`, warnings contain
  `deprecatedNumeric`.
- Evidence: E7.
- Source line discharged by V1: `values.size and is_numlike` remains true for
  non-empty numeric data.

## PO-3: Non-empty categorical conversion has no numeric warning

- Formal claim: `CONVERT-NONEMPTY-CATEGORICAL`.
- Precondition: `N > 0`, `AllNumlike == false`, `UpdateAccepts == true`.
- Required postcondition: status `ok`, result size `N`, warnings list empty.
- Evidence: E5, E8, E9.
- Source behavior: false numeric guard falls through to `unit.update(values)`
  and mapped categorical return.

## PO-4: Non-empty invalid categorical conversion still fails

- Formal claim: `CONVERT-NONEMPTY-INVALID`.
- Precondition: `N > 0`, `AllNumlike == false`, `UpdateAccepts == false`.
- Required postcondition: status `typeError`, warnings list empty.
- Evidence: E8.
- Source behavior: false numeric guard still delegates validation to
  `UnitData.update`.

## PO-5: Empty update suppresses all-convertible log

- Formal claim: `UPDATE-EMPTY-CONVERTIBLE`.
- Precondition: `N == 0`, `AllConvertible == true` by possible vacuity.
- Required postcondition: status `ok`, logs list empty.
- Evidence: E6, E10.
- Source line discharged by V1: `if data.size and convertible:`.

## PO-6: Non-empty all-convertible update preserves informational log

- Formal claim: `UPDATE-NONEMPTY-CONVERTIBLE`.
- Precondition: `N > 0`, `AllConvertible == true`.
- Required postcondition: status `ok`, logs contain `allConvertible`.
- Evidence: E6 and existing source behavior.
- Source line discharged by V1: `data.size and convertible` remains true for
  non-empty all-convertible data.

## PO-7: Public compatibility is unchanged

- Formal/audit artifact: `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Precondition: public callers invoke the existing methods/signatures.
- Required postcondition: no signature, return-shape, registry, or dispatch
  protocol change.
- Evidence: E11 and static callsite search.
- Source behavior: V1 changes only branch predicates inside existing methods.
