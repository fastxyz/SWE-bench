# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Target

Audited function:

```python
def prepare_value(self, value):
    if isinstance(value, InvalidJSONInput):
        return value
    return json.dumps(value, ensure_ascii=False, cls=self.encoder)
```

The proof covers partial correctness of this straight-line branch structure for the form/admin display contract. There are no loops or recursive calls in the target.

## Formal Core

K artifacts:

- `fvk/mini-json-form.k`
- `fvk/jsonfield-prepare-value-spec.k`

Claims:

- `CLAIM-PREPARE-INVALID`: invalid input is returned as raw input.
- `CLAIM-PREPARE-UNICODE-CHINA`: the issue's concrete non-ASCII discriminator reaches the readable Unicode display state.
- `CLAIM-PREPARE-GENERAL`: all non-invalid JSON values reach `jsonDumps(V, false, E)`.

The proof is intentionally small because the source change is a one-branch parameter change and no loop invariant is needed.

## Constructed Proof Sketch

### Invalid branch

Initial state:

```k
<k> prepareValue(invalidInput(S), E) </k>
```

The `prepareValue` invalid-input rule fires:

```k
<k> raw(S) </k>
```

This discharges `PO-001` and `F-002`. No `jsonDumps` transition is reachable on this branch, so invalid submitted JSON is not overquoted.

### Non-ASCII display branch

Initial state for the public issue discriminator:

```k
<k> prepareValue(jstring(chinaText), E) </k>
```

The non-invalid branch rule fires because `isInvalid(jstring(chinaText)) => false`:

```k
<k> jsonDumps(jstring(chinaText), false, E) </k>
```

The display serialization rule for `ensure_ascii=False` rewrites:

```k
<k> displayUnicodeChina </k>
```

The legacy/default ASCII path is represented separately:

```k
jsonDumps(jstring(chinaText), true, E) => displayEscapedChina
```

Because the candidate reaches `displayUnicodeChina` and not `displayEscapedChina`, the proof distinguishes the fixed behavior from the reported bug. This discharges `PO-002` and resolves `F-001`.

### General non-invalid branch

Initial state:

```k
<k> prepareValue(V, E) </k>
requires notBool isInvalid(V)
```

The non-invalid branch rule fires:

```k
<k> jsonDumps(V, false, E) </k>
```

The symbolic encoder `E` is preserved in the reached term. This discharges `PO-004`; combined with the `json.dumps` `ensure_ascii` semantics, it also supports `PO-003` for ASCII-only values.

### Frame obligations

`PO-005` is discharged by source-frame inspection: V1 changes only `repo/django/forms/fields.py`, while database serialization remains in `repo/django/db/models/fields/json.py` with the pre-existing `json.dumps(value, cls=self.encoder)` call.

`PO-006` is discharged by source-frame inspection: `BoundField`, `Widget`, `Textarea`, and the textarea template remain unchanged. The returned display string continues through Django's normal template rendering path.

`PO-007` is discharged by composing the source path `BoundField.value()` -> `JSONField.bound_data()` -> `JSONField.prepare_value()` with `CLAIM-PREPARE-GENERAL`.

## Adequacy Result

The formal English claims match the intent-only requirements in `SPEC.md`:

- The non-ASCII display claim is prompt-derived, not implementation-derived.
- The invalid-input preservation claim is source-derived compatibility for an existing public form behavior and is not in conflict with the issue.
- The database serialization frame condition is prompt-derived from the issue discussion.
- The custom encoder and widget rendering frame conditions are source/API compatibility obligations.

No claim preserves the legacy escaped Unicode display behavior; that behavior is marked as the bug in `F-001`.

## Residual Risk

The proof is constructed but not machine-checked. The K files and commands are emitted, but the task forbids running `kompile`, `kast`, or `kprove`.

The mini semantics abstracts the full Python `json` library as `jsonDumps`. That is sufficient for the audited property because the property axis is exactly the `ensure_ascii` flag and the discriminator distinguishes `ensure_ascii=True` from `ensure_ascii=False`.

Termination is not separately proved. The target function has no loops; termination depends on Python's `json.dumps()` terminating for finite JSON-serializable inputs in the intended domain.

## Future Machine Check

Do not run these in this workspace. In a future environment with K installed:

```sh
cd fvk
kompile mini-json-form.k --backend haskell
kast --backend haskell jsonfield-prepare-value-spec.k
kprove jsonfield-prepare-value-spec.k
```

Expected result if machine-checked successfully: `#Top`.

## Test Guidance

No tests were modified. Future tests to add or keep are listed in `ITERATION_GUIDANCE.md`. No test should be removed based on this constructed proof alone.
