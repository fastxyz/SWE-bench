# FVK Notes

I kept the V1 source change unchanged.

Decision D1: keep the dependency split in `ConditionSet._eval_subs`.
Trace: F1 identifies the original bug, and PO1/PO2 show that returning the
substituted base when the true condition is dummy-independent fixes the reported
`ImageSet` case.

Decision D2: do not broaden the fix to `return base` for all `cond is S.true`
cases.
Trace: F2 records the over-correction risk, and PO3 requires preserving the
legacy dummy-dependent fallback supported by public in-repo tests.

Decision D3: do not edit `ImageSet`, `Contains`, `Basic._subs`, or test files.
Trace: F1 localizes the root cause to `ConditionSet._eval_subs`; E3 says plain
`ImageSet.subs` already works; F4 plus PO5/PO6 show no compatibility issue or
dispatch change; the task forbids test edits.

Decision D4: treat the formal proof as constructed but not machine-checked.
Trace: F3 and PO8 record that the abstract K model is adequate for the reported
return-shape branch but is not a full SymPy semantics, and this environment
forbids running K tooling.

Decision D5: add FVK artifacts only, with no further production source edits.
Trace: F1/F2/F4 and PO1-PO6 justify V1 as the production fix; F3 plus PO7/PO8
justify adding an abstract formal core and proof notes rather than changing more
SymPy code.

No additional production source changes were justified by the FVK findings.
