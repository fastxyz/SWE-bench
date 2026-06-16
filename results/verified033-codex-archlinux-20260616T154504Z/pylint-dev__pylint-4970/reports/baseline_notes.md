# Baseline Notes

## Root cause

The duplicate-code checker treated `min-similarity-lines` only as a numeric
threshold and did not give `0` an explicit disabled meaning. The rcfile option
is parsed as an integer and copied to `Similar.min_lines`, after which the
similarity computation still ran through the normal duplicate-code path. A zero
threshold therefore lowered the check instead of clearly turning it off.

## Changed files

`repo/pylint/checkers/similar.py`

- Added a guard in `Similar._compute_sims()` that returns no similarities when
  `self.min_lines <= 0`. This is the shared computation path used by the pylint
  checker, the map/reduce reduction path, and the standalone `symilar` command,
  so the disabled behavior is applied consistently before any matching work is
  attempted.
- Updated the `min-similarity-lines` option help to document that `0` disables
  the check.

## Assumptions and alternatives

- I treated `0` as a sentinel that disables duplicate-code detection, matching
  the issue description. I also made negative values produce no similarities
  because a negative minimum line count is not meaningful and should not enter
  the chunking algorithm.
- I considered adding the guard inside `hash_lineset()`, but that would leave
  the checker walking file pairs and calling the lower-level hashing function.
  Guarding in `_compute_sims()` stops the check earlier and covers all callers
  that consume computed similarities.
- I considered disabling the entire `SimilarChecker` during option preparation,
  but that would require changes in broader linter/checker scheduling code. The
  issue is local to similarity computation, so the smaller local fix is safer.
- I did not add or modify tests because this task requires the test suite to
  remain fixed and hidden.
