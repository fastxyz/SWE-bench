# Intent Spec

Status: constructed, not machine-checked.

## Public obligations

1. Marker skips point at the test item.

   Evidence: `benchmark/PROBLEM.md` says the expected report for
   `@pytest.mark.skip` is `test_it.py:3: unconditional skip`.

   Obligation: for reports created from `pytest.mark.skip` or
   `pytest.mark.skipif`, the final skipped-report `longrepr` location is the
   item definition location, not the internal `skip()` raise site.

2. `--runxfail` is limited to xfail behavior.

   Evidence: `benchmark/PROBLEM.md` says "`--runxfail` is only about xfail and
   should not affect this at all."

   Obligation: enabling `runxfail` must not change marker-skip location
   reporting.

3. Runtime skips remain distinct from marker skips.

   Evidence: `src/_pytest/skipping.py` stores `skipped_by_mark_key` only when
   `evaluate_skip_marks(item)` triggers, and the issue discusses
   `@pytest.mark.skip` / `skipif`, not imperative `pytest.skip()`.

   Obligation: the item-location rewrite applies to marked skips, not to every
   skipped report.

4. Existing xfail report behavior is preserved when `--runxfail` is absent.

   Evidence: the option help text says `--runxfail` reports xfail tests as if
   unmarked; without that option, existing xfail-specific report rewrites remain
   the intended behavior.

   Obligation: adding a guard to fix `runxfail` must not suppress the normal
   xfail-exception and xfailed-branch report rewrites when `runxfail` is false.
