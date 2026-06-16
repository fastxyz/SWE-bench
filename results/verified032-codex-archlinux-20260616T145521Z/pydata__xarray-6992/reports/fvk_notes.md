# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found the same operative defect as the
baseline pass: `reset_index(..., drop=True)` must not propagate coordinate names
whose variables were removed. The current source expression:

```python
coord_names = self._coord_names & variables.keys() | set(new_variables)
```

is retained because it discharges the proof obligations in
`fvk/PROOF_OBLIGATIONS.md`.

## Trace to Findings and Obligations

F-001 traces the pre-fix failure to PO-2, PO-3, PO-4, and PO-5. In the MCVE
state, the old formula left `z` in `_coord_names` after removing `z` from
`_variables`, making `DataVariables.__len__` negative. The retained V1 formula
computes `C' = (C intersect V') union N`, yielding `{a, b}` instead of
`{z, a, b}`.

F-002 traces the preservation side of the fix to PO-6, PO-7, and PO-8. The
intersection keeps old coordinate names that still have variables, and the
union with `set(new_variables)` keeps replacement index variables as
coordinates. This is why the audit did not replace V1 with a simpler
subtraction-only formula.

F-003 traces the rejected `DataVariables.__len__` alternative to PO-2 and PO-4.
Changing only the length calculation would hide the negative length symptom but
would not restore `_coord_names <= _variables.keys()`.

F-004 records that no blocking finding remains. The constructed proof in
`fvk/PROOF.md` covers the intended name-set transition, and PO-9 confirms there
is no public API or test-file change.

## Artifacts and Execution

The FVK artifacts are under `fvk/`, including the requested markdown files and
the constructed K files. The K commands are recorded in `fvk/PROOF.md` and
`fvk/PROOF_OBLIGATIONS.md`, but were not executed because this task forbids K
tooling. No tests or Python code were run.
