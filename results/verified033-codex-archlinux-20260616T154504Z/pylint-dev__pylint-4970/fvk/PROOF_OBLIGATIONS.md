# Proof Obligations

Constructed, not machine-checked.

| ID | Obligation | Evidence / proof sketch | Status |
| --- | --- | --- | --- |
| PO1 | Rcfile/option value reaches checker state as `self.min_lines`. | `SimilarChecker.set_option()` delegates validation to `BaseChecker.set_option()` and then assigns `self.min_lines = self.config.min_similarity_lines` for `min-similarity-lines`. | Discharged by inspection. |
| PO2 | If `self.min_lines <= 0`, `SimilarChecker.process_module()` does not collect module data. | V2 adds an early return before `node.stream()` and `append_stream()`. | Discharged by V2. |
| PO3 | If `self.min_lines <= 0`, `Similar._compute_sims()` returns `[]` and does not call `_iter_sims()`. | V1/V2 guard returns immediately before `no_duplicates` construction and the loop over `_iter_sims()`. | Discharged by V1/V2. |
| PO4 | If `_compute_sims()` returns `[]`, `SimilarChecker.close()` emits no `R0801` and stats remain zero. | `duplicated` starts at `0`; the `for num, couples in self._compute_sims()` loop has zero iterations; `add_message()` is only inside that loop; stats are assigned from `duplicated`. | Discharged by control flow. |
| PO5 | Parallel map/reduce runs preserve disabled behavior. | `reduce_map_data()` creates `recombined`, copies `min_lines`, calls `open()`, combines data, then `close()`. PO3 and PO4 apply to `recombined`; with PO2, worker map data is empty in disabled runs. | Discharged by control flow. |
| PO6 | For `self.min_lines > 0`, existing behavior is preserved. | Both guards are false, so `process_module()` reaches the original `with node.stream()` body and `_compute_sims()` reaches the original similarity algorithm. | Discharged by branch analysis. |
| PO7 | Direct `Similar` / standalone `symilar` disabled behavior is covered. | These paths call `_compute_sims()` through `Similar.run()` or directly; PO3 gives empty similarities. Standalone still reads files so its existing total-line reporting path remains available. | Discharged by control flow. |
| PO8 | User-facing option help documents the sentinel. | The `min-similarity-lines` help text now states `0 disables the check`. | Discharged by source diff. |
