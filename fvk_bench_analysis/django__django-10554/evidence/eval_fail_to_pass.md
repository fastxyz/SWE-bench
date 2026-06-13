# Eval result — results/.../eval/fvk.report.json

resolved = False ; patch_successfully_applied = True

FAIL_TO_PASS.failure (2):
  - test_union_with_values_list_and_order (queries.test_qs_combinators.QuerySetSetOperationTests)
  - test_union_with_values_list_on_annotated_and_unannotated (queries.test_qs_combinators.QuerySetSetOperationTests)

PASS_TO_PASS.success (23) — includes:
  - test_order_raises_on_non_selected_column   <-- NOTE: a PASS_TO_PASS, not a FAIL_TO_PASS.
        It guards the "still raise for ALIASED columns" half of the gold fix
        (the `if col_alias: raise` branch). The gold patch preserves it.
  - test_ordering, test_ordering_by_f_expression, test_simple_union, etc.

(baseline.report.json and control.report.json are identical -> baseline failed
identically; zero flips, consistent with the macro context.)

## NOTE on a sub-agent discrepancy (resolved here authoritatively):
The root-cause extractor listed `test_order_raises_on_non_selected_column` as a
FAIL_TO_PASS; the eval report shows it is a PASS_TO_PASS. The two true FAIL_TO_PASS
are the ones above (extractor conflated the gold patch's *test edits* with this run's
FAIL_TO_PASS set). The forensics agent's list matches the eval report.
