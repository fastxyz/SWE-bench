# Proof Obligations

Status: obligations constructed for static FVK; not machine-checked.

## PO-1: Collapsed `A-B` line keeps `B-C` metadata

Precondition:

- `A == B`
- `C != A`

Postcondition:

- `type == LINE`
- Coordinates are canonicalized to `A-C-A`
- Result `ab == old bc`

Rationale: `A-B` is the collapsed edge; `B-C` is a non-collapsed retained segment. `withinLine` consumes result `ab`.

## PO-2: Other degenerate line branches keep valid `ab`

Precondition A:

- `A == C`
- `A != B`

Postcondition A:

- `type == LINE`
- Coordinates remain `A-B-A`
- Result `ab == old ab`

Precondition B:

- `B == C`
- `A != B`
- `A != C`

Postcondition B:

- `type == LINE`
- Coordinates become `A-B-A`
- Result `ab == old ab`

Rationale: in both cases the represented line segment read by query code is `A-B`, whose metadata is already `ab`.

## PO-3: Point and triangle classification remain unchanged

Precondition point:

- `A == B == C`

Postcondition point:

- `type == POINT`

Precondition triangle:

- `A`, `B`, and `C` are pairwise distinct

Postcondition triangle:

- `type == TRIANGLE`
- Coordinates and edge flags are unchanged

## PO-4: Query bridge from decoded line to `CONTAINS`

Precondition:

- `decodeTriangle` returns `type == LINE`

Postcondition:

- LatLon and XY `CONTAINS` query paths pass result `ab` to `withinLine`.

Rationale: PO-1 fixes the exact metadata consumed by the search path named in the issue.

## PO-5: Compatibility and frame

Postcondition:

- No public signatures, enum constants, field widths, or test files change.
- Non-degenerate triangle behavior is preserved.
- Tessellation edge detection is not modified.

## PO-6: Honesty gate

Postcondition:

- K commands are emitted but not executed.
- The proof and any test-redundancy statements are labeled constructed, not machine-checked.
