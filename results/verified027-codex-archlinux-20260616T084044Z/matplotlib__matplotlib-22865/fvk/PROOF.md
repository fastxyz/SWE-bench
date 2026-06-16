# Constructed Proof

Status: constructed, not machine-checked.  Per the task constraints, no K
tooling was run.

## Claims proved

The formal claims are in `fvk/colorbar-segments-spec.k` and use the semantics
fragment in `fvk/mini-colorbar-segments.k`.

The proof establishes partial correctness of the divider segment selection:
for every `N >= 2`, every valid `extend` value, and both `drawedges` states,
the selected half-open boundary-row range is exactly the range specified in
`fvk/SPEC.md`.

There are no loops or recursion in the modeled selector, so no circularity
claim is needed.

## Proof sketch

1. Model state:
   - `N` is the number of rows in `np.dstack([X, Y])`;
   - each row is abstracted to its index;
   - `select(drawedges, extend, N)` returns either `emptySegments` or a
     half-open `range(start, stop)`.
2. Case split on `drawedges`.
   - If `drawedges` is `false`, the only matching rule rewrites to
     `emptySegments`, matching C1 and PO2.
3. For `drawedges=true`, case split on `extend`.
   - `ExtNeither` rewrites to `range(1, N - 1)`, matching PO3.
   - `ExtMin` rewrites to `range(0, N - 1)`, matching PO3 and PO4.
   - `ExtMax` rewrites to `range(1, N)`, matching PO3 and PO5.
   - `ExtBoth` rewrites to `range(0, N)`, matching PO4 and PO5.
4. PO7 maps those ranges back to Python slice semantics:
   - `stop=None` corresponds to `N`;
   - `stop=-1` corresponds to `N - 1`.
5. PO6 frames orientation: horizontal colorbars swap coordinate components,
   but the row index selected by the slice continues to identify the same
   long-axis boundary.

## Source correspondence

V1 computes:

```python
start = 0 if self.extend in ('both', 'min') else 1
stop = None if self.extend in ('both', 'max') else -1
```

Thus:

- `'neither'` maps to `Rows[1:-1]` -> `range(1, N - 1)`;
- `'min'` maps to `Rows[0:-1]` -> `range(0, N - 1)`;
- `'max'` maps to `Rows[1:None]` -> `range(1, N)`;
- `'both'` maps to `Rows[0:None]` -> `range(0, N)`.

The original failing behavior used `Rows[1:-1]` for every extension value, so
it fails C3, C4, and C5.

## Machine-check commands

These commands are recorded for a later environment with K installed.  They
were not executed here.

```sh
cd fvk
kompile mini-colorbar-segments.k --backend haskell
kast --backend haskell colorbar-segments-spec.k
kprove colorbar-segments-spec.k
```

Expected machine-check result after successful proof: `#Top`.

## Test guidance

No tests were removed or edited.  If the K proof is machine-checked later,
unit assertions that only check the selected divider row range for the five
formal cases are subsumed by the proof.  Image-comparison and backend tests
should be kept because this proof does not cover pixel rendering, clipping,
or antialiasing.
