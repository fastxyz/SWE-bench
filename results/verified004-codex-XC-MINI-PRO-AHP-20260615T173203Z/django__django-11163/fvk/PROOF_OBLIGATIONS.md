# Proof Obligations

Status: constructed, not machine-checked.

## PO-FIELDS-DISTINCTION

The implementation must distinguish `fields=None` from a provided empty list.

- Source: E-001, E-002, E-003.
- Formal claim: `MODEL-TO-DICT-EMPTY-FIELDS` and the `someFields(.Names)` branch
  in `MODEL-TO-DICT-GENERAL`.
- Discharge status: constructed. In V1, `fields is not None` is true for `[]`,
  so every field whose name is not in the empty list is skipped.

## PO-EMPTY-FIELDS

For all finite model field sequences `FS` and any `exclude`, calling
`model_to_dict(instance, fields=[])` returns `{}`.

- Source: E-001, E-002.
- Formal claim: `MODEL-TO-DICT-EMPTY-FIELDS`.
- Discharge status: constructed. The helper circularity processes every field
  through the "not requested" branch and leaves the result map empty.

## PO-GENERAL-SELECTION

For all finite model field sequences, `model_to_dict()` returns exactly the
editable fields whose names pass the inclusion and exclusion filters.

- Source: E-003, E-004, E-005.
- Formal claim: `MODEL-TO-DICT-GENERAL`.
- Discharge status: constructed by symbolic execution over the field-sequence
  helper.

## PO-EXCLUDE-PRECEDENCE

If a field name is present in both `fields` and `exclude`, the field is excluded.

- Source: E-004.
- Formal claim: `MODEL-TO-DICT-GENERAL`.
- Discharge status: constructed. The add branch requires
  `notBool excluded(EXCLUDE, NAME)`.

## PO-NON-EDITABLE-SKIP

Non-editable fields are never returned.

- Source: implementation shape and the function's Form-initial purpose.
- Formal claim: `MODEL-TO-DICT-GENERAL`.
- Discharge status: constructed. The non-editable branch does not update the
  result map or read log.

## PO-FILTER-BEFORE-READ

Fields rejected by editability, inclusion, or exclusion filters are not read.

- Source: E-006.
- Formal claim: `MODEL-TO-DICT-GENERAL` plus read-log postcondition.
- Discharge status: constructed. The only branch that appends to the read log is
  the same branch that inserts into the result map.

## PO-CALLSITE-COMPATIBILITY

The repair must preserve the function signature and existing callers while
changing `fields=[]` behavior.

- Source: E-007.
- Formal/compatibility artifact: `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Discharge status: satisfied. V1 changes only an internal branch condition; the
  function signature, return type, and call sites are unchanged.

## PO-MACHINE-CHECK

The proof must be reproducible later with K tooling, but this session must not
run it.

- Source: FVK verify honesty gate and user constraints.
- Commands:

```sh
kompile fvk/mini-python.k --backend haskell
kast --backend haskell fvk/model-to-dict-spec.k
kprove fvk/model-to-dict-spec.k
```

- Discharge status: commands recorded, not executed.
