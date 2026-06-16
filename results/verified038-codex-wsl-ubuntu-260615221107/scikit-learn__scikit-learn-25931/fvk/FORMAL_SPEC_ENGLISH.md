# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases the nontrivial claims in
`fvk/iforest-fit-spec.k`.

## C-FIT-NON-AUTO-NO-WARNING

For any accepted training input represented as a DataFrame with valid feature
names, and any fixed non-auto contamination value, `fit` first records that
feature names were seen and converts the local training data to its validated
internal dense representation. It then computes the offset from the private
score of that internal representation. The warning list remains empty.

## C-FIT-NON-AUTO-OFFSET-FRAME

For fixed contamination, the offset produced by `fit` is exactly the percentile
of the raw private score on the same validated training representation. The
claim abstracts the numeric raw score and percentile, but preserves which data
representation is scored and that no public validation step contributes to the
offset.

## C-PUBLIC-SCORE-ARRAY-AFTER-NAMES-WARNS

If an estimator already has fitted feature names and a public caller passes an
array-like input with no feature names to `score_samples`, the public validation
step emits the standard "invalid feature names" warning and then returns the
private raw score for the validated dense representation.

## C-PUBLIC-SCORE-DATAFRAME-AFTER-NAMES-NO-WARN

If an estimator already has fitted feature names and a public caller passes a
DataFrame-style input with matching valid feature names to `score_samples`, the
public validation step emits no warning and returns the private raw score for
the validated dense representation.

## C-FIT-AUTO-UNCHANGED

For DataFrame-style training input and `contamination == "auto"`, `fit` records
feature names, validates the data, and sets the abstract auto offset without
calling the scoring path to define the offset. The warning list remains empty.

## C-SPARSE-FIT-SCORES-CSR

For sparse training input and fixed contamination, `fit` validates the sparse
input to the fitting representation, and the private scoring path converts that
representation to CSR before the abstract raw score is computed. The offset is
the percentile of the CSR raw score.

## C-PRIVATE-SCORE-NO-VALIDATION-WARNING

Calling the private scorer on an already validated dense representation does
not inspect fitted feature names and does not append feature-name warnings. It
returns the abstract raw score for that representation.
