# Iteration Guidance

## Applied in V2

- Added a `SimilarChecker.process_module()` early return for `self.min_lines <= 0`
  to discharge FINDINGS F2 and PROOF_OBLIGATIONS PO2.
- Kept the V1 `_compute_sims()` guard to discharge F1, PO3, PO4, PO5, and PO7.
- Kept the V1 help text update to discharge PO8.

## Do not change now

- Do not alter checker registration or global `prepare_checkers()` behavior. The
  public issue can be satisfied locally in the similarity checker, and changing
  scheduling would have a wider compatibility surface.
- Do not remove the `_compute_sims()` guard just because `process_module()` now
  skips collection in pylint. Direct `Similar` users, standalone `symilar`, and
  defensive reduce-path behavior still need the shared guard.
- Do not edit tests in this task.

## Future work

- Consider explicit option validation for negative `min-similarity-lines` if
  project maintainers want negatives rejected instead of treated as disabled.
- Consider updating sample rcfile comments to mention the `0` sentinel if the
  project treats those files as user documentation.
- In an execution-capable environment, run the normal pylint test subset and add
  focused tests listed in `fvk/PROOF.md`.

## Machine-check commands

Recorded for later, not executed:

```sh
kompile fvk/mini-python-similar.k --backend haskell
kast --backend haskell fvk/similar-spec.k
kprove fvk/similar-spec.k
```
