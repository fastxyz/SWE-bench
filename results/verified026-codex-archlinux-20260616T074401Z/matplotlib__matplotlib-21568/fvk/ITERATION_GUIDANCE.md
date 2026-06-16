# FVK Iteration Guidance

## Decision

V1 stands unchanged. The FVK audit found that V1 discharges the intended
separator-protection obligations while preserving compatible alphabetic
splitting and formatter APIs.

## Source Changes for V2

None.

## Why No Further Code Edit Is Justified

- Finding F1 is fixed by V1's colon and space replacements.
- Finding F2 explains why legacy public expectations with raw spaces/colons are
  suspect for this bug.
- Finding F3 rejects the broader one-block monkey-patch form as unnecessary to
  meet the public spacing intent.
- Finding F4 confirms the helper-level fix reaches all built-in TeX date
  formatter paths.

## Suggested Tests for a Future Normal Test Pass

Do not add or edit tests in this benchmark task. In a normal development pass,
use tests like:

- `_wrap_in_tex("2020-01-01 00:00")` contains `2020{-}01{-}01\;00{:}00`.
- TeX-enabled `AutoDateFormatter` time labels use `{:}` for `HH:MM:SS`.
- TeX-enabled `ConciseDateFormatter` offset strings use `\;` between date and
  time.
- Month-name labels still keep alphabetic runs outside math chunks unless the
  project intentionally switches to a future `\text`-based implementation.

## Open Boundaries

The proof is constructed over a mini string semantics and was not
machine-checked. It does not prove TeX pixel metrics, backend-specific layout,
or arbitrary TeX escaping.
