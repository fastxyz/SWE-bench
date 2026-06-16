# Public Compatibility Audit

## Changed public symbols

No public method signatures, return types, message IDs, option names, or report
IDs were changed.

## Callers and overrides

- `Similar._compute_sims()` keeps the same signature and return type. Direct
  callers still receive `List[Tuple[int, Set[LinesChunkLimits_T]]]`; disabled
  states now receive an empty list.
- `SimilarChecker.process_module()` keeps the same signature. It now has an
  early return only when duplicate-code checking is disabled.
- `SimilarChecker.close()` was not changed. Its existing loop over
  `_compute_sims()` handles the disabled empty-list result.
- `SimilarChecker.reduce_map_data()` was not changed. It copies `min_lines` into
  the recombined checker before `close()`, so the disabled behavior is preserved
  in parallel mode.

## Compatibility verdict

Compatible. The change is behavioral only for the disabled sentinel and does not
require public callsite or subclass updates.
