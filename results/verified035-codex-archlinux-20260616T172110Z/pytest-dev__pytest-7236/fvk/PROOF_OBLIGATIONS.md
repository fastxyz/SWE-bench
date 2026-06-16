# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Skipped Under PDB Does Not Run Delayed TearDown

Intent evidence: E-1, E-2.

Formal claim: `SKIPPED-UNDER-PDB`.

Precondition: pytest is in `--pdb` mode, and unittest does not call `tearDown`
for the test case. This is the unittest behavior for a method skipped by
`@unittest.skip` before `setUp`, the test body, or `tearDown`.

Postcondition: pytest's delayed-teardown count is unchanged and
`_explicit_tearDown` is empty after pytest item teardown.

Discharge status: proved constructively by symbolic execution of V1's
replacement-teardown recording rule. Not machine-checked.

## PO-2: Reached TearDown Under PDB Still Runs Exactly Once Later

Intent evidence: E-4, E-5.

Formal claim: `REACHED-TEARDOWN-UNDER-PDB`.

Precondition: pytest is in `--pdb` mode, and unittest reaches and calls
`tearDown` on the test case.

Postcondition: pytest's delayed-teardown count increases by exactly one and
`_explicit_tearDown` is empty after pytest item teardown.

Discharge status: proved constructively by symbolic execution. Not
machine-checked.

## PO-3: Non-PDB Path Does Not Schedule Delayed TearDown

Intent evidence: E-2.

Formal claim: `NO-PDB-NO-DELAYED-CALL`.

Precondition: pytest is not in `--pdb` mode.

Postcondition: this delayed-teardown mechanism does not add a delayed
`tearDown` call. Direct unittest behavior is outside this delayed-call count.

Discharge status: proved constructively by symbolic execution. Not
machine-checked.

## PO-4: Public Compatibility Is Preserved

Intent evidence: I-4 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

Formal claim: compatibility audit, not a K reachability claim.

Obligation: no public method signature, hook signature, unittest result
callback, subclass override contract, or producer/consumer shape changes.

Discharge status: satisfied by static source inspection.

## PO-5: Adequacy And Discriminator Check

Intent evidence: E-1 through E-6 and `fvk/SPEC_AUDIT.md`.

Obligation: the claims must express public intent rather than V1 behavior, and
the model must distinguish the buggy predecessor from V1.

Discharge status: satisfied. The predecessor behavior would save `tearDown`
before unittest ran; with `unittestCallsTearDown = false`, pytest teardown would
still call it, violating PO-1.
