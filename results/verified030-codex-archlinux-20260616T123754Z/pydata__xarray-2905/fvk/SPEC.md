# FVK Spec

Status: constructed, not machine-checked.

## Target

The target is `repo/xarray/core/variable.py`, specifically
`as_compatible_data(data, fastpath=False)` and the public issue paths that call
it:

- `Variable.__setitem__(self, key, value)`.
- `DataArray.__init__(..., data, dims=[])` through `_check_data_shape` and
  `as_compatible_data`.

## Public Intent Ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. Critical entries:

- E1-E5: the reported bug is coercion of arbitrary objects with a `.values`
  property during object-array assignment; the expected output preserves the
  original object.
- E6-E9: object arrays should support non-string Python objects, and the generic
  `.values` probe should become explicit type checking.
- E8: the same problem applies to scalar `DataArray(..., dims=[])`
  construction.
- E10-E13: existing pandas/xarray container and adapter behavior is a frame
  condition.
- E14-E15: both public issue paths pass through `as_compatible_data`, which
  makes the helper the correct repair and proof unit.

## Domain

The proof domain is the helper's in-memory data-normalization behavior for these
input classes:

- Arbitrary scalar Python objects that have a `.values` attribute but are not
  recognized xarray/pandas containers.
- Known xarray/pandas containers: `xarray.DataArray`, `xarray.Variable`,
  `pandas.Series`, `pandas.DataFrame`, and this repository's compatibility
  `pandas.Panel`.
- Existing supported array/index adapters, including `pandas.Index` and
  `PandasIndexAdapter`-style inputs.

The proof intentionally abstracts away the full NumPy/pandas internals but keeps
the observable that matters for this issue: whether the output contains the
original object or the `.values` payload.

## Contract

C1. `as_compatible_data(arbitrary_values_object)` must not read or return the
object's `.values` payload. It must fall through to ordinary object conversion,
which yields object data containing the original object.

C2. Scalar `Variable.__setitem__` assignment of an arbitrary `.values` object
must store the original object because it delegates to C1 before scalar wrapping
and assignment.

C3. Scalar `DataArray(..., dims=[])` construction with an arbitrary `.values`
object must store the original object because it delegates to C1 after shape
checking.

C4. Known self-described containers remain intentionally unwrapped:
`pandas.Series`, `pandas.DataFrame`, `pdcompat.Panel`, and `xarray.DataArray`
use `.values`; `xarray.Variable` uses the existing `data.data` branch.

C5. Existing adapter and special-value behavior remains unchanged:
`pandas.Index`/supported non-NumPy arrays return through `_maybe_wrap_data`,
timestamps/timedeltas keep their scalar conversions, and masked arrays keep
their existing mask handling.

## Formal Artifacts

- `mini-python.k` defines the minimal K-style semantics fragment for
  `as_compatible_data` classification and the two public delegation paths.
- `xarray-variable-spec.k` states claims for C1-C5 and a negative
  characterization of the pre-V1 bug.
- `FORMAL_SPEC_ENGLISH.md` paraphrases each claim.
- `SPEC_AUDIT.md` confirms the claim paraphrases match this intent spec.

## Verdict

V1 satisfies C1-C5 by replacing the unconditional `getattr(data, "values",
data)` with an explicit type check for the known containers while preserving the
existing earlier branches. No V2 production-code change is justified by the FVK
audit.
