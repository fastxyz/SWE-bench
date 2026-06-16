# FVK Specification

Status: constructed for FVK audit; not machine-checked.

## Scope

This FVK pass audits the V1 source change in
`repo/lib/matplotlib/colorbar.py`, specifically the divider segment selection
inside `Colorbar._add_solids`.

The observable under specification is the list slice passed to
`self.dividers.set_segments(...)`.  The model abstracts each row of
`np.dstack([X, Y])` to its boundary index:

- index `0` is the main-body boundary adjacent to the data minimum side;
- index `N - 1` is the main-body boundary adjacent to the data maximum side;
- interior indices `1` through `N - 2` are ordinary internal color boundaries.

`range(A, B)` in the K artifacts denotes the half-open list of selected
boundary indices `[A, ..., B - 1]`.

## Contract

For `N >= 2`, `drawedges`, and `extend` in
`{'neither', 'min', 'max', 'both'}`:

| drawedges | extend | Expected divider segment indices |
| --- | --- | --- |
| `False` | any valid value | empty |
| `True` | `'neither'` | `range(1, N - 1)` |
| `True` | `'min'` | `range(0, N - 1)` |
| `True` | `'max'` | `range(1, N)` |
| `True` | `'both'` | `range(0, N)` |

This matches V1:

```python
if self.drawedges:
    start = 0 if self.extend in ('both', 'min') else 1
    stop = None if self.extend in ('both', 'max') else -1
    self.dividers.set_segments(np.dstack([X, Y])[start:stop])
else:
    self.dividers.set_segments([])
```

With Python slice semantics over a sequence of length `N`, `stop=None` means
`N`, and `stop=-1` means `N - 1`.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.  The critical entries
are:

- E1 and E2: the issue and `drawedges` API require black divider lines at color
  boundaries, including both extension/body joins for `extend='both'`.
- E4 and E5: public API docs define `drawedges` and the valid extension states.
- E7: `_do_extends` does not draw the join line at the extension base, so the
  divider collection is the correct mechanism.
- E8: `_mesh()` makes boundary rows orientation-independent for this selection
  problem; horizontal orientation swaps coordinate components, not row meaning.

## Adequacy

The abstraction is property-complete for this bug because the pre-fix behavior
and V1 behavior map to different formal values.  For example, with
`drawedges=True`, `extend='both'`, and `N=10`:

- pre-fix selection: `range(1, 9)`;
- required and V1 selection: `range(0, 10)`.

The model intentionally does not prove backend rendering, antialiasing,
clipping, z-ordering, or exact pixel output.  Those are outside the V1 code
change and remain integration/rendering test concerns.
