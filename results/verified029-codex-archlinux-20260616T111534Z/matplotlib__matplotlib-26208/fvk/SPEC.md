# FVK Specification: shared-axis unit inheritance

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Scope

This FVK pass audits the V1 production change in
`repo/lib/matplotlib/axes/_base.py`, specifically `sharex()` and `sharey()`.
The modeled observable is the reported `dataLim` state of an original axes
after:

1. the original axes has categorical x units and stackplot data limits from a
   `PolyCollection`;
2. a twin axes is created with `sharex`;
3. the twin plots string x data.

The proof obligations also cover the symmetric `sharey()` edit because V1
made the same unit-inheritance change there.

## Intent Spec

- I1. Plotting on a twin axes must not replace the original axes'
  already-established `dataLim` with `[inf, -inf]`.
- I2. The bug is tied to unit handling for string categorical values on shared
  axes, not to ordinary numeric plotting.
- I3. A newly created twin axis that shares an axis with an existing axes should
  use the shared axis' unit conversion state when it has no unit state of its
  own.
- I4. Sharing an axis should not clobber a receiving axis that has already
  established its own unit state; the issue's `twinx()` path creates a fresh
  receiving x-axis with no units.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "dataLims of the first axis (ax1) get changed to +/-inf when plotting a stackplot on the second axis (ax2)" | Reproduction path must preserve `ax1.dataLim` after later plotting on `ax2`. | Encoded by S3 / PO3. |
| E2 | prompt | "To not change ax1 dataLims, since I made no changes to it" | Frame condition: operations on the twin must not mutate the original axes' data limits. | Encoded by S3 / PO4. |
| E3 | prompt hint | "do not use the unit machinery ... creating the twin before you plot to either ... edge case in the unit handling code" | The causal mechanism is a late unit update on a shared axis. | Encoded by S1 and legacy counterexample. |
| E4 | code comments | `sharex=None,  # use Axes instance's xaxis info` and `sharex()` "Share the x-axis with other" | A new shared axis should inherit axis information when it has none. | Encoded by S1/S2. |
| E5 | code docs | `Axes.relim()`: "Collection instances are not supported" | A broad `relim()`-for-collections rewrite is not part of the existing public contract. | Recorded as rejected alternative F5. |

## Abstract State

The formal model tracks only the state needed to distinguish the bug from the
fix:

- `ax1HasUnits`, `ax2HasUnits`: whether an axis has converter or units
  according to `Axis.have_units()`.
- `ax1Units`, `ax2Units`: abstract unit object identity. For categorical data,
  sharing the same unit object means sharing the same `UnitData` mapping.
- `ax1Converter`, `ax2Converter`: abstract converter identity.
- `ax1DataLim`, `ax2DataLim`: either `valid` or `null`.
- `ax1RelimCount`: whether a units callback invoked `Axes.relim()` on the
  original axes after the stackplot.

The abstraction deliberately keeps the collection geometry opaque. The
observable property is whether `ax1.dataLim` remains valid or is reset to a
null `Bbox`.

## Contracts

S1. `sharex(self, other)` unit-inheritance contract:
If `self.xaxis.have_units()` is false when sharing is established, then after
`sharex`, `self.xaxis.converter == other.xaxis.converter` and
`self.xaxis.units == other.xaxis.units`.

S2. `sharey(self, other)` symmetric contract:
If `self.yaxis.have_units()` is false when sharing is established, then after
`sharey`, `self.yaxis.converter == other.yaxis.converter` and
`self.yaxis.units == other.yaxis.units`.

S3. Reported `twinx()` preservation contract:
For any initial state matching the issue path:

- `ax1.xaxis.have_units()` is true from categorical stackplot input;
- `ax1.dataLim` is valid from stackplot's `fill_between` data update;
- `ax2.xaxis.have_units()` is false when `twinx()` creates the receiving axis;
- `ax2` shares x with `ax1`;

then a later `ax2.plot(string_x, numeric_y)` does not call `set_units()` on the
shared x-axis group and does not invoke `ax1._unit_change_handler("x")`.
Therefore `ax1.dataLim` remains valid.

S4. Existing-unit receiver frame contract:
If the receiving axis already has units, `sharex()` / `sharey()` must leave
that unit state alone. This is an implementation-preservation condition with
public compatibility support from the fact that `sharex()` is a public method
and can be called on non-fresh axes.

## Formal Core

The constructed K core is in:

- `fvk/mini-mpl-units.k`
- `fvk/share-units-spec.k`

The K model is a mini-semantics of the relevant Matplotlib unit-sharing state,
not a full Python or Matplotlib semantics.

Expected machine-check commands, not run here:

```sh
kompile fvk/mini-mpl-units.k --backend haskell
kast --backend haskell fvk/share-units-spec.k
kprove fvk/share-units-spec.k
```

## Adequacy Summary

The formal English in `fvk/FORMAL_SPEC_ENGLISH.md` matches I1-I4 in
`fvk/INTENT_SPEC.md`. The model preserves the observable that matters for the
issue: `ax1.dataLim` remains valid versus becoming null. It intentionally does
not prove full Matplotlib drawing, autoscaling, or collection relim support.
