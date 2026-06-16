# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found no new source defect after mapping the
public intent to proof obligations.

## Decisions Traced to Findings and Obligations

1. Kept the conditional first-entry removal.
   - Findings: F1, F2.
   - Proof obligations: PO-1, PO-2.
   - Reason: the issue requires preserving a first entry such as `"something"`
     while still removing `""`, `"."`, or `os.getcwd()`.

2. Kept the guarded `_remove_sys_path_entry` helper for later startup slots.
   - Findings: F3.
   - Proof obligations: PO-3, PO-4, PO-5.
   - Reason: a second blind `pop` in the `PYTHONPATH` branches could recreate
     the same class of bug. Guarding the target slot preserves public
     `PYTHONPATH` cleanup while preventing removal of non-CWD caller paths.

3. Kept the shifted indices when the first entry is preserved.
   - Findings: F3.
   - Proof obligations: PO-3, PO-4.
   - Reason: once V1 preserves a caller-owned first entry, the documented
     leading and trailing implicit-CWD cleanup targets are one slot later than
     they are after a first-entry removal.

4. Did not add path normalization.
   - Findings: F5.
   - Proof obligations: PO-1, PO-2.
   - Reason: the public issue names only `""`, `"."`, and exact
     `os.getcwd()`. Normalizing broader path equivalents would be a larger
     policy change without public evidence.

5. Did not remove later CWD-like entries globally.
   - Findings: F4.
   - Proof obligations: PO-6.
   - Reason: the existing docstring identifies later entries as legitimate for
     editable installs.

6. Did not modify public API or call sites.
   - Findings: no compatibility defect.
   - Proof obligations: PO-7.
   - Reason: the bug is internal path-list mutation behavior; changing the
     signature or call protocol is unnecessary.

## Verification Status

The proof is constructed, not machine-checked. Per the task constraints, I did
not run tests, Python, `kompile`, `kast`, or `kprove`; the commands are recorded
in the FVK artifacts for a later environment.
