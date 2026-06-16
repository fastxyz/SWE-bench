# Proof Obligations

Status: constructed, not machine-checked.

## PO-001 - Empty Storage Characterization

Claim:

`hasCountStorage()` is false exactly when both `sparseCounts == null` and
`denseCounts == null`.

Justification:

The helper returns `sparseCounts != null || denseCounts != null`. Therefore its
negation is equivalent to both stores being null.

Finding links:

- F-001
- F-003

## PO-002 - `getTopChildren` Empty Result

Preconditions:

- `topN > 0`.
- `dim.equals(field)`.
- `path.length == 0`.
- `sparseCounts == null`.
- `denseCounts == null`.
- `totalDocCount == 0`.

Postcondition:

- The method returns `new FacetResult(field, new String[0], 0, new LabelAndValue[0], 0)`.
- No dereference of `denseCounts` or `sparseCounts` occurs on this path.

Source anchor:

- `StringValueFacetCounts.getTopChildren`, guard at lines 181-186 in V1.

Finding links:

- F-001
- F-004

## PO-003 - `getAllChildren` Empty Result

Preconditions:

- `dim.equals(field)`.
- `path.length == 0`.
- `sparseCounts == null`.
- `denseCounts == null`.
- `totalDocCount == 0`.

Postcondition:

- The method returns `new FacetResult(field, new String[0], 0, new LabelAndValue[0], 0)`.
- No dereference of `denseCounts` or `sparseCounts` occurs on this path.

Source anchor:

- `StringValueFacetCounts.getAllChildren`, guard at lines 146-151 in V1.

Finding links:

- F-002
- F-004

## PO-004 - Validation Is Preserved for `getTopChildren`

Preconditions:

- Any call to `getTopChildren`.

Postcondition:

- `validateTopN(topN)` and `validateDimAndPathForGetChildren(dim, path)` execute
  before the empty-storage guard.
- Invalid inputs still throw through existing validation rather than receiving an
  empty result.

Finding links:

- F-004

## PO-005 - `getSpecificValue` Existing Term Empty Count

Preconditions:

- `dim.equals(field)`.
- `path.length == 1`.
- `docValues.lookupTerm(path[0]) >= 0`.
- `sparseCounts == null`.
- `denseCounts == null`.
- `totalDocCount == 0`.

Postcondition:

- The method returns `0`.
- No dereference of `denseCounts` occurs.

Finding links:

- F-002
- F-004

## PO-006 - `getSpecificValue` Absent Term

Preconditions:

- `dim.equals(field)`.
- `path.length == 1`.
- `docValues.lookupTerm(path[0]) < 0`.

Postcondition:

- The method returns `-1` before consulting count storage.

Finding links:

- F-002

## PO-007 - Non-Empty Storage Paths Are Unchanged

Preconditions:

- `sparseCounts != null || denseCounts != null`.
- Public input validation succeeds.

Postcondition:

- `getTopChildren` and `getAllChildren` continue into the existing sparse or dense
  counting loops.
- `getSpecificValue` returns the existing sparse or dense count lookup.

Finding links:

- F-004

## PO-008 - `getAllDims` Inherits Empty Top-Children Semantics

Preconditions:

- `topN > 0`.
- `sparseCounts == null`.
- `denseCounts == null`.
- `totalDocCount == 0`.

Postcondition:

- `getAllDims(topN)` returns a singleton list containing the empty
  `getTopChildren(topN, field)` result.

Finding links:

- F-004

## PO-009 - Compatibility

Preconditions:

- Public source callsites and subclasses compile against existing signatures.

Postcondition:

- V1 introduces no public signature, constructor, return-type, or override-shape
  changes.

Finding links:

- F-004
