# Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "Setting `min-similarity-lines` to `0` should stop pylint from checking duplicate code" | `0` is a disable sentinel for the duplicate-code check. | Encoded in SPEC C1-C3 and K claims DISABLED-COMPUTE / DISABLED-PROCESS. |
| E2 | prompt | "Setting `min-similarity-lines` to `0` in the rcfile doesn't disable checking for duplicate code" | Rcfile/configured value must reach the checker state used by duplicate detection. | Encoded in PROOF_OBLIGATIONS PO1. |
| E3 | prompt | "it instead treats every line of code as duplicate and raises many errors" | With `0`, no `duplicate-code` messages may be emitted for duplicate files. | Encoded in SPEC C3 and PROOF_OBLIGATIONS PO4. |
| E4 | prompt | "Setting `min-similarity-lines` to `0` should disable the duplicate code check." | Disable is stronger than merely raising the threshold differently. | Encoded in SPEC C2 and FINDINGS F2. |
| E5 | prompt hint | "The way to disable duplicate code is by using ... `disable=duplicate-code`" | Existing full-message disable remains an alternative; this issue is a separate enhancement for the numeric option. | Scope note; no need to change global checker scheduling. |
| E6 | prompt hint | "impossible to disable duplicate-code in some part of the code and not the other ... another issue" | Do not introduce partial/block-level disable semantics here. | Encoded as out-of-scope in SPEC and ITERATION_GUIDANCE. |
| E7 | code/comment | `SimilarChecker` doc says duplicate computation may be memory / CPU intensive. | A disabled path should avoid collection/matching work where local to the checker. | Supports FINDINGS F2 and V2 process-module guard. |
| E8 | implementation | `SimilarChecker.set_option()` copies `self.config.min_similarity_lines` to `self.min_lines`. | The formal path may model the option as `min_lines` in checker state. | Encoded in PROOF_OBLIGATIONS PO1. |
