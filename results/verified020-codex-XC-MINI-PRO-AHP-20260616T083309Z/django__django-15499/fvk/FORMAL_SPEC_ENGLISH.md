# FORMAL SPEC ENGLISH

Status: constructed, not machine-checked.

K claim `CREATE-ALTER-MANAGERS-REDUCES` says:

For any create operation with model name `N`, fields `F`, options `O`, bases
`B`, and managers `M0`, and any same-model manager alteration with managers
`M1`, the reduction result is exactly one create operation with the same
`N/F/O/B` and managers `M1`.

K claim `TWO-STEP-STATE` says:

Applying the original two-operation sequence creates the model and then replaces
its managers, ending with model state `(F, O, B, M1)`.

K claim `ONE-STEP-STATE` says:

Applying the optimized one-operation sequence creates the model directly with
model state `(F, O, B, M1)`.

K claim `DIFFERENT-MODEL-NOT-ABSORBED` says:

If the create operation and manager alteration target different model names,
this specific same-model absorption does not occur.
