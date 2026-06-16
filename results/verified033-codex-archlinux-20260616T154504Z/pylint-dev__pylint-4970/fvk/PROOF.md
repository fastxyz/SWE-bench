# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests,
Python code, or project commands were executed.

## Claims proved

- DISABLED-PROCESS: `min_lines <= 0` makes `SimilarChecker.process_module()` a
  no-op for duplicate-code data collection.
- DISABLED-COMPUTE: `min_lines <= 0` makes `Similar._compute_sims()` return
  `[]`.
- DISABLED-CLOSE: an empty similarity list makes `SimilarChecker.close()` emit
  no `R0801` and assign zero duplicate stats.
- POSITIVE-PRESERVATION: `min_lines > 0` follows the original implementation.
- PARALLEL-REDUCE: parallel reduction inherits the disabled behavior.

## Symbolic proof sketch

1. Option propagation (PO1): after configuration sets
   `min-similarity-lines` to `0`, `SimilarChecker.set_option()` stores that
   integer in `self.min_lines`.
2. Module processing (PO2): in `process_module()`, symbolic execution case
   splits on `self.min_lines <= 0`. In the disabled branch, the first statement
   returns. The stream-opening and `append_stream()` statements are unreachable,
   so `linesets` is framed unchanged.
3. Similarity computation (PO3): in `_compute_sims()`, the same disabled guard
   returns `[]` before `_iter_sims()` is evaluated. Therefore no file-pair
   matching, hashing, or duplicate grouping occurs.
4. Close behavior (PO4): `close()` initializes `duplicated = 0`. The loop over
   `_compute_sims()` has no iterations when `_compute_sims()` is `[]`; the only
   `add_message("R0801", ...)` call is inside that loop. The final stats writes
   use `duplicated`, so duplicated-line stats are zero.
5. Positive preservation (PO6): for `self.min_lines > 0`, both new guards are
   false and the original statements execute in the original order.
6. Parallel reduction (PO5): `reduce_map_data()` copies `min_lines` to the
   recombined checker before `close()`. Applying steps 3 and 4 to that checker
   proves no parallel duplicate-code messages in the disabled state.

## Formal artifacts

The K artifacts are intentionally abstract and model only the property-carrying
state for this fix:

- `fvk/mini-python-similar.k`
- `fvk/similar-spec.k`

Exact commands to run later, not executed here:

```sh
kompile fvk/mini-python-similar.k --backend haskell
kast --backend haskell fvk/similar-spec.k
kprove fvk/similar-spec.k
```

Expected machine-check result: `#Top` for the DISABLED-PROCESS,
DISABLED-COMPUTE, DISABLED-CLOSE, POSITIVE-PRESERVATION, and PARALLEL-REDUCE
claims.

## Residual risk

- This is a partial-correctness proof; termination and performance are not
  proved.
- The K files are a mini semantics, not full Python/Pylint semantics.
- The proof is constructed but not machine-checked.
- Existing tests should be kept until the K commands and the normal test suite
  can be run in an execution-capable environment.

## Test guidance

Do not remove tests. Add focused tests in a normal development environment for:

- rcfile or direct checker configuration `min-similarity-lines=0` with duplicate
  files emits no `duplicate-code`;
- `SimilarChecker.process_module()` with `min_lines=0` leaves `linesets`
  unchanged;
- positive thresholds still produce the existing duplicate-code behavior.
