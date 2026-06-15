# FVK Notes

## Decisions

1. Kept V1's core delegation from `ExpressionWrapper` to the wrapped expression.
   - Trace: `fvk/FINDINGS.md` F-001; `fvk/PROOF_OBLIGATIONS.md` PO-001,
     PO-002, PO-003.
   - Reason: the reported bug is exactly that the wrapper inherited
     `BaseExpression.get_group_by_cols()` and contributed itself for wrapped
     constants. Delegating to `Value.get_group_by_cols()` returns `[]`.

2. Improved V1 by preserving the missing-`alias` deprecation path for wrapped
   legacy child expressions.
   - Trace: `fvk/FINDINGS.md` F-002; `fvk/PROOF_OBLIGATIONS.md` PO-004,
     PO-005.
   - Change: `ExpressionWrapper.get_group_by_cols()` now inspects
     `self.expression.get_group_by_cols`. If the child method lacks an `alias`
     parameter, it emits `RemovedInDjango40Warning` and calls the child method
     without the keyword.
   - Reason: Django 3.2 source and public tests show that custom expressions
     missing `alias=None` are deprecated but still handled. V1 would have
     forwarded `alias` through the wrapper and risked a `TypeError`.

3. Did not change `BaseExpression`, `Value`, SQL compiler code, or tests.
   - Trace: `fvk/FINDINGS.md` F-003; `fvk/PROOF_OBLIGATIONS.md` PO-005.
   - Reason: `Value` already has the intended `[]` behavior, and the defect is
     the wrapper dispatch point. Test files are fixed and hidden by instruction.

4. Did not run tests, Python, or K tooling.
   - Trace: `fvk/FINDINGS.md` F-004; `fvk/PROOF_OBLIGATIONS.md` PO-006.
   - Reason: the task forbids execution. The K commands are recorded in
     `fvk/PROOF.md` for a future environment and labeled constructed, not
     machine-checked.

## Changed files

- `repo/django/db/models/expressions.py`: added `warnings` and
  `RemovedInDjango40Warning` imports; added
  `ExpressionWrapper.get_group_by_cols()` with alias-aware delegation and a
  missing-alias compatibility branch.
- `fvk/`: added the required FVK audit artifacts plus the mini-K formal core and
  adequacy/compatibility audit files.
- `reports/fvk_notes.md`: this decision trace.

## Final conclusion

V1 was correct for the reported constant `ExpressionWrapper(Value(...))` case
but incomplete against the broader public compatibility contract. V2 is the
minimal improvement justified by the FVK audit.
