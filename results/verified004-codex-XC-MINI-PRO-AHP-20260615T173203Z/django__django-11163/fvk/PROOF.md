# Constructed Proof

Status: constructed, not machine-checked.

## Claims

The formal core is split across:

- `mini-python.k`: a small semantics for the `model_to_dict()` field loop.
- `model-to-dict-spec.k`: the proof claims.

The main claims are:

- `MODEL-TO-DICT-GENERAL`: for every finite field sequence, the result equals
  the intent-derived selected dictionary and the read log contains exactly the
  selected field names.
- `FILTER-FIELDS-CIRCULARITY`: helper circularity over the field sequence.
- `MODEL-TO-DICT-EMPTY-FIELDS`: for `fields=[]`, the result and read log are
  empty for every field sequence.

## Proof Sketch

`model_to_dict()` initializes `data = {}` and iterates through the finite field
sequence from model metadata.

For each field, symbolic execution splits into these branches:

1. `editable` is false. The code continues without updating `data` and without
   reading a value.
2. `fields is not None` and the field name is not in `fields`. The code
   continues without updating `data` and without reading a value.
3. `exclude` contains the field name. The code continues without updating
   `data` and without reading a value.
4. The field passes all filters. The code reads the field value and updates
   `data[f.name]`.

The helper circularity is by structural progress over the remaining field
sequence. The base case is an empty field sequence, where the accumulated map
and read log are returned unchanged. In the inductive case, one field is
processed by exactly one of the branches above, and the circularity is invoked
on the remaining sequence with the shifted accumulator.

For `fields=[]`, the formal value is `someFields(.Names)`. The predicate
`requested(someFields(.Names), NAME)` is false for every `NAME`. Therefore every
editable field takes branch 2, every non-editable field takes branch 1, and no
branch can update the map or read log. The post-state is `result(.Map, .Names)`.

## Why V1 Discharges the Obligations

The V1 condition is:

```python
if fields is not None and f.name not in fields:
```

For `fields=[]`, the left side is true and `f.name not in fields` is true for
all field names. The function therefore skips every field before
`f.value_from_object(instance)` is reached.

For `fields=None`, the left side is false, preserving the no-inclusion-filter
behavior. For non-empty `fields`, only listed names can pass the inclusion
filter. The existing `exclude` check still runs after inclusion and before the
value read, preserving exclude precedence.

## Adequacy

The English meaning of the K claims matches the intent entries:

- Empty provided field list returns an empty dictionary: E-001 and E-002.
- Provided field lists restrict output to named fields: E-003.
- `None` remains the no-filter sentinel: E-003.
- `exclude` wins over `fields`: E-004.
- Skipped fields are not read: E-006.

No claim depends on hidden tests, evaluator output, or upstream implementation
knowledge.

## Machine Check Commands

These commands were not run in this session:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/model-to-dict-spec.k
kprove fvk/model-to-dict-spec.k
```

Expected result after a successful machine check: `kprove` reduces all claims to
`#Top`.

## Test Recommendation

Do not remove tests in this benchmark. If the K claims are machine-checked later,
unit tests that only assert in-domain `model_to_dict()` field-selection examples
would be candidates for redundancy review. Boundary, integration, and regression
tests should be kept unless separately audited.
