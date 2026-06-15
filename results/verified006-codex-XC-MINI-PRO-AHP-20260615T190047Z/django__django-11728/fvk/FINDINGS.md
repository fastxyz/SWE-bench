# FVK Findings

Status: constructed from formalization and proof-obligation review, not from
test execution.

## F1: V1 correctly addressed the reported trailing named-group defect

- Input: `entries/(?P<pk>[^/.]+)/relationships/(?P<related_field>\w+)`
- V0 observed behavior from public issue:
  `entries/<pk>/relationships/(?P<related_field>\w+)`
- Expected behavior from public issue:
  `entries/<pk>/relationships/<related_field>`
- Cause: the pre-V1 scanner checked `unmatched_open_brackets == 0` only at the
  start of the next iteration. With no next character after the closing `)`, the
  final span was never recorded.
- Resolution: V1 moved the check after processing the current character and
  recorded the slice through `idx + 1`. FVK confirms this satisfies POB-N1.

## F2: V1 needed the analogous final unnamed-group behavior

- Input: `a/(\w+)`
- V0 observed behavior by code inspection: `a/(\w+)`
- Expected behavior from the public hint: `a/<var>`
- Cause: `replace_unnamed_groups()` had the same next-iteration completion test
  as `replace_named_groups()`.
- Resolution: V1 moved the unnamed scanner's completion check after processing
  the current character and records the end index through the closing `)`.
  FVK confirms this satisfies POB-U1.

## F3: V1 left a reconstruction bug for multiple unnamed groups

- Input: `a/(\w+)/b/(\d+)`
- V1 observed behavior by symbolic reconstruction: the second replacement would
  append the prefix again, producing a duplicated-prefix result rather than a
  single preserved path.
- Expected behavior from the helper docstring's plural contract:
  `a/<var>/b/<var>`
- Cause: the reconstruction loop appended `pattern[:start] + '<var>'` for every
  selected group. That is only correct for the first selected span.
- Resolution: V2 uses a single cursor initialized to `0`, appending
  `pattern[prev_end:start]`, then `<var>`, then the final suffix. This satisfies
  POB-U3.

## F4: V1 left edge cases in unnamed outermost-span filtering

- Input: adjacent groups `a/(\w+)(\d+)`
- V1 observed behavior by symbolic filtering: the second group was skipped
  because `start > prev_end` rejected adjacent spans where `start == prev_end`.
- Expected behavior: `a/<var><var>`.
- Additional input: nested separated groups such as `a/((x)y(z))`
- V1 observed behavior by symbolic filtering: after skipping a nested group, the
  old code updated `prev_end` to the skipped nested span's end, allowing a later
  nested group inside the same outer span to be selected.
- Expected behavior: the outer group consumes the nested groups and yields
  `a/<var>`.
- Resolution: V2 updates `prev_end` only when a span is selected and selects a
  span when `prev_end is None or start >= prev_end`. This satisfies POB-U2.

## F5: No public compatibility break found

- Public callsite: `simplify_regex()` still calls `replace_named_groups()` then
  `replace_unnamed_groups()`.
- Signatures: unchanged.
- Return type: string, unchanged.
- Resolution: no compatibility code edit required. This discharges C1.

## Residual findings

- The proof is constructed, not machine-checked. Test deletion is not
  recommended unless a human later runs the emitted K commands and gets `#Top`.
- Full Python `re` syntax is not modeled. The proof targets the helper's
  balanced-parenthesis span logic because that is where the public issue and V1
  residual findings localize.
