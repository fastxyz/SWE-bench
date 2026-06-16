# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims

The formal claims are in `xarray-variable-spec.k`:

- `ARBITRARY-VALUES-PRESERVED`
- `SCALAR-SETITEM-PRESERVES-ARBITRARY-VALUES-OBJECT`
- `SCALAR-DATAARRAY-CONSTRUCT-PRESERVES-ARBITRARY-VALUES-OBJECT`
- `KNOWN-CONTAINER-UNWRAPS-VALUES`
- `VARIABLE-AND-ADAPTER-FRAME`
- `NON-NUMPY-SUPPORTED-FRAME`
- `PRE-V1-BUG-CHARACTERIZATION` as negative evidence only

## Proof Sketch

### PO1: arbitrary `.values` objects are preserved

For an input represented as `arbitraryValuesObject(PAYLOAD)`, V1 source
inspection gives this control flow through `as_compatible_data`:

1. It is not a `Variable`.
2. It is not one of `NON_NUMPY_SUPPORTED_ARRAY_TYPES`.
3. It is not a tuple, timestamp, or timedelta in the modeled issue case.
4. It is not an instance of the explicit values-unwrapping tuple:
   `pd.Series`, `pd.DataFrame`, `pdcompat.Panel`, or `xr.DataArray`.
5. Therefore the old generic `.values` read is not performed.
6. The value reaches ordinary array conversion as the original object.

The K semantics models steps 4-6 as:

```k
asCompatible(arbitraryValuesObject(PAYLOAD))
=> maybeWrap(numpyAsarray(arbitraryValuesObject(PAYLOAD)))
=> maybeWrap(objectArray(arbitraryValuesObject(PAYLOAD)))
=> objectArray(arbitraryValuesObject(PAYLOAD))
```

This discharges `ARBITRARY-VALUES-PRESERVED`.

### PO2: scalar assignment preserves the object

`Variable.__setitem__` computes the indexer and then, for non-`Variable` values,
calls `as_compatible_data(value)`. For scalar assignment, the resulting
zero-dimensional object data is wrapped as `Variable((), value)` before being
assigned to the indexable backing data. The only defect-producing step was the
helper's generic `.values` read; PO1 removes that step.

The K semantics models the delegation as:

```k
scalarSetitem(arbitraryValuesObject(PAYLOAD))
=> asCompatible(arbitraryValuesObject(PAYLOAD))
=> objectArray(arbitraryValuesObject(PAYLOAD))
```

This discharges `SCALAR-SETITEM-PRESERVES-ARBITRARY-VALUES-OBJECT`.

### PO3: scalar DataArray construction preserves the object

`DataArray.__init__` calls `_check_data_shape` and then
`as_compatible_data(data)` before inferring coords/dims and creating a
`Variable`. With `dims=[]` and no coords, the issue path is scalar helper
conversion. PO1 therefore applies to construction as well.

The K semantics models the delegation as:

```k
scalarDataArrayConstruct(arbitraryValuesObject(PAYLOAD))
=> asCompatible(arbitraryValuesObject(PAYLOAD))
=> objectArray(arbitraryValuesObject(PAYLOAD))
```

This discharges
`SCALAR-DATAARRAY-CONSTRUCT-PRESERVES-ARBITRARY-VALUES-OBJECT`.

### PO4 and PO5: compatibility frame conditions

Known self-described containers take explicit or earlier branches:

- `Variable` returns `data.data` before the edited branch.
- `pd.Index` and supported adapter arrays return through
  `NON_NUMPY_SUPPORTED_ARRAY_TYPES` and `_maybe_wrap_data` before the edited
  branch.
- `pd.Series`, `pd.DataFrame`, `pdcompat.Panel`, and `xr.DataArray` match the
  explicit values-unwrapping tuple and still use `.values`.

The K semantics models these as:

```k
asCompatible(knownValuesContainer(ndarrayData(PAYLOAD)))
=> ndarrayResult(ndarrayData(PAYLOAD))
asCompatible(variableData(PAYLOAD)) => variablePayload(PAYLOAD)
asCompatible(nonNumpySupported(PAYLOAD)) => wrapped(PAYLOAD)
```

These discharge `KNOWN-CONTAINER-UNWRAPS-VALUES`,
`VARIABLE-AND-ADAPTER-FRAME`, and `NON-NUMPY-SUPPORTED-FRAME`.

### Negative pre-V1 characterization

The pre-V1 behavior was:

```k
preV1ValuesStep(arbitraryValuesObject(otherObject(PAYLOAD)))
=> maybeWrap(numpyAsarray(otherObject(PAYLOAD)))
=> ndarrayResult(otherObject(PAYLOAD))
```

This derives the issue symptom: the `.values` payload is stored instead of the
original object. Because E2 marks that behavior as the bug, it is not used as a
desired postcondition.

## Adequacy

`SPEC_AUDIT.md` checks every English paraphrase in
`FORMAL_SPEC_ENGLISH.md` against the intent clauses in `INTENT_SPEC.md`. All
required audited behaviors pass. No claim depends on the pre-fix output as a
desired result.

## Residual Risk

- Constructed, not machine-checked: the K files and commands have not been run.
- The mini semantics abstracts full NumPy/pandas internals and proves only the
  object-versus-payload dispatch property needed for this issue.
- Termination of external library conversion is outside the proof.
- No tests were run or edited by instruction.

## Machine-Check Commands Not Run

From the workspace root, an environment with K installed would use:

```sh
cd fvk
kompile mini-python.k --backend haskell
kast --backend haskell xarray-variable-spec.k
kprove xarray-variable-spec.k
```

Expected result after a successful machine check: `#Top` for all claims.

## Test Recommendation

Do not remove tests based on this constructed proof. If test edits were allowed,
add focused tests for F1/F2 plus frame tests for known containers. Existing
tests around pandas/xarray construction and adapter preservation should be kept
until both the K claims and project tests can be run.
