# Proof Obligations

Status: constructed, not machine-checked.

## Target Representation Obligations

PO-B1. Base/regression identity:
For all target vectors `Y`, `BaseHistGradientBoosting._get_y_for_scorer(Y)`
returns `Y`.

Status: discharged by `HGB-GET-Y-BASE`.

PO-C1. Classifier decode:
For all valid classifier class arrays `C` and internal encoded target vectors
`Y`, `HistGradientBoostingClassifier._get_y_for_scorer(Y)` returns the vector
`C[Y.astype(np.intp)]`.

Status: discharged by `HGB-GET-Y-CLASSIFIER`.

PO-C2. Valid-code precondition:
Every encoded classifier target passed to `_get_y_for_scorer` is an
integer-valued valid index into `classes_`.

Status: discharged from source flow: `_encode_y` uses
`LabelEncoder.fit_transform`, assigns `classes_`, and casts encoded values to
`Y_DTYPE`. This is the formal `validCodes(CLASSES, YS)` precondition.

## Scorer Call Obligations

PO-S1. Training scorer:
`_check_early_stopping_scorer` passes `_get_y_for_scorer(y_small_train)` as the
training scorer target.

Status: discharged by the source call at lines 433-435 and by
`HGB-SCORER-CLASSIFIER-VAL`, `HGB-SCORER-CLASSIFIER-NOVAL`,
`HGB-SCORER-BASE-VAL`, and `HGB-SCORER-BASE-NOVAL`.

PO-S2. Validation scorer:
When `_use_validation_data` is true, `_check_early_stopping_scorer` passes
`_get_y_for_scorer(y_val)` as the validation scorer target.

Status: discharged by the source call at lines 438-441 and by
`HGB-SCORER-CLASSIFIER-VAL` and `HGB-SCORER-BASE-VAL`.

PO-S3. No-validation branch:
When `_use_validation_data` is false, `_check_early_stopping_scorer` does not
call the validation scorer and decides early stopping from `train_score_`.

Status: discharged by source lines 438-445 and by the `*-NOVAL` claims.

## Frame Obligations

PO-L1. Loss scoring unchanged:
The `scoring='loss'` path remains in `_check_early_stopping_loss` and continues
to use encoded/internal targets.

Status: discharged by source lines 339-353; no V1 edits touch this path.

PO-P1. Public prediction unchanged:
Classifier `predict` continues to return `self.classes_[encoded_classes]`.

Status: discharged by source lines 974-989; no V1 edits touch this method.

PO-API1. Public API compatibility:
No public method signature, constructor signature, scorer signature, prediction
shape, or score-array shape changes.

Status: discharged by `PUBLIC_COMPATIBILITY_AUDIT.md`.

## Test and Verification Obligations

PO-T1. Regression-test recommendation:
A future test should cover string labels with scorer-based early stopping.

Status: open test gap by task constraint; no test files modified.

PO-V1. Machine-checking:
Run the emitted `kompile`, `kast`, and `kprove` commands before treating the
proof as machine-verified or removing redundant tests.

Status: open by environment constraint; commands are listed in `PROOF.md`.
