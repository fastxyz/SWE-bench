# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not change the production source beyond V1. The FVK audit found that V1's
guard in `record_typehints()` satisfies the public issue intent and preserves
the required frame conditions.

## Why V1 Stands

- F1 and PO1 show the reported `autoclass` leak is removed because class
  descriptions no longer record `"return"` annotations.
- F3 and PO3 show the fix is narrow enough: functions and methods still record
  return annotations for description-mode `rtype` output.
- F4 and PO2 justify the `exception` branch of the guard as class-like behavior,
  supported by public docs and the `ExceptionDocumenter` inheritance path.
- F2 explains why legacy public tests expecting a class-level `Return type:
  None` should not force a rollback.

## Recommended Next Test Changes

Do not edit tests in this benchmark task. For a normal upstream change, add or
update coverage for:

- `autoclass` with `autodoc_typehints = "description"` and
  `__init__(...) -> None`, asserting no class-level `Return type` field.
- Function and method cases with return annotations, asserting their `Return
  type` fields still appear in description mode.
- Optionally, `autoexception` with a constructor return annotation, asserting no
  exception-level return type field.

## Open Questions

No public-intent blocker remains. The only residual risk is external mutation of
`env.temp_data['annotations']` by third-party extensions before
`merge_typehints()`; that is outside the reported issue and outside the
production source change justified here.
