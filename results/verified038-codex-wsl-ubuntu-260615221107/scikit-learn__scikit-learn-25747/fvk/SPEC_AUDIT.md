# Spec Audit

Status: constructed, not machine-checked.

| Formal clause | Intent coverage | Verdict |
| --- | --- | --- |
| Existing `DataFrame` index is preserved in the pandas auto-wrap path even when original and output lengths differ. | E1-E4 require removing the reported length-mismatch source and treating existing DataFrame indexes as defined. | Pass |
| Existing `DataFrame` columns are updated when resolved feature names exist. | E5 requires preserving `set_output` column naming. | Pass |
| Existing `DataFrame` columns are preserved when column-name resolution fails. | Existing helper docstring says callable column errors have columns=None semantics; no issue evidence requires a change. | Pass |
| Non-DataFrame dense output uses the supplied/original index when converted to a new `DataFrame`. | E3 says only set index when not defined; non-DataFrame output has no DataFrame index before construction. | Pass |
| Sparse output raises. | E6 documents existing sparse rejection; the issue is dense pandas DataFrame wrapping. | Pass |
| Default output and disabled auto-wrap return unchanged data. | Existing `_wrap_data_with_container` API and non-pandas behavior are outside the bug and should be preserved. | Pass |
| Direct `Series` output is outside the formal domain. | The helper docstring names `{ndarray, dataframe}`; the issue's Series-like transformer output reaches the helper as a `DataFrame` after FeatureUnion concatenation. | Ambiguous but non-blocking; recorded in F3 |

Adequacy conclusion: the claims cover the public failure mechanism and the
changed helper behavior. The only ambiguity is direct Series wrapping, which is
not necessary to justify V1 for this issue and is not used as a proof premise.
