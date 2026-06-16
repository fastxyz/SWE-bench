# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or pytest commands were run.

## Formal Core

The mini semantics is in `fvk/mini-pytest-xfail.k`.

The claims are in `fvk/pytest-xfail-spec.k`.

Expected future machine-check commands, not run in this session:

```sh
kompile fvk/mini-pytest-xfail.k --backend haskell
kast --backend haskell fvk/pytest-xfail-spec.k
kprove fvk/pytest-xfail-spec.k
```

Expected machine-check result if the mini semantics and claims are accepted:
`#Top`.

## Adequacy Gate

The intent-only spec requires that a dynamic xfail marker added through
`request.node.add_marker` during the test body be visible to call-report xfail
handling. The K claim `dynamic_xfail_body` paraphrases to the same behavior: a
state with no cached active xfail, followed by an xfail marker addition and a
failed call, reaches a skipped/xfailed report with the xfail reason.

No claim depends on the buggy pytest 6 output as expected behavior. That output
is recorded as Finding FVK-F1.

## Proof Sketch

1. Setup evaluates xfail marks with no xfail marker visible. By
   `_evaluate_xfail_marks_with_store`, the cache contains no active xfail and
   the cached marker count is `0`. This discharges PO2 for the setup phase.

2. The call hook runs before the test body. With no active xfail, V1 preserves
   the previous behavior of re-evaluating when `xfailed is None`, then stores
   count `0`. This does not report or skip anything by itself.

3. The test body adds `pytest.mark.xfail(reason="xfail")` through the public
   marker API. `Node.add_marker` appends or inserts a `Mark`; therefore
   `_xfail_mark_count(item)` increases from `0` to `1`. This establishes the
   stale-cache premise for PO4.

4. The test body fails with an assertion error. The report hook receives a call
   report that is not skipped, is not an imperative `pytest.xfail()` exception,
   and is not under `--runxfail`.

5. In the marker-based report path, `_xfail_marks_changed(item)` compares cached
   count `0` with current count `1`, so it is true. V1 calls
   `_evaluate_xfail_marks_with_store(item)`, which evaluates the newly visible
   xfail marker and stores both the active `Xfail(reason="xfail", ...)` and
   count `1`.

6. The existing marker branch sees `call.excinfo` and an active xfail with no
   `raises` mismatch. It sets `rep.outcome = "skipped"` and
   `rep.wasxfail = "xfail"`. This discharges PO5 and the main claim.

7. For report precedence, the refresh is below unittest unexpected-success,
   `--runxfail`, and imperative `pytest.xfail()` branches, and inside
   `elif not rep.skipped`. Those earlier outcomes are unchanged. This discharges
   PO7.

8. For strict, raises, and XPASS behavior, V1 only changes when xfail state is
   refreshed. Once refreshed, the pre-existing report branch still applies the
   same `raises`, `strict`, and pass/fail logic. This discharges PO6.

## Test-Redundancy Recommendation

No tests were modified. Because the proof is not machine-checked, no test should
be removed based on this FVK pass. After future successful `kprove`, a focused
unit test for the exact issue path would be subsumed by `dynamic_xfail_body`, but
integration and broader pytest reporting tests should remain.

## Conclusion

The constructed proof discharges the public-intent obligations for V1. No source
change beyond V1 is justified by this FVK audit.
