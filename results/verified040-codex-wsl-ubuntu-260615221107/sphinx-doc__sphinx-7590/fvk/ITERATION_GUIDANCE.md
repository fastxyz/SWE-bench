# Iteration Guidance

Status: final guidance for the V2 patch.

## Decisions

1. Keep V1's `ASTUserDefinedLiteral` wrapper and suffix helper.
   - Trace: F1, F3; PO-NUM-1, PO-CHAR-1, PO-RENDER-1.
   - Reason: it fixes the reported numeric failure and avoids corrupting
     `ASTCharLiteral` decoding.

2. Improve V1's string handling.
   - Trace: F2; PO-STR-1, PO-STR-2.
   - Reason: V1 attached suffixes only after unprefixed `"..."` strings, which
     under-covered the C++ UDL family. V2 extends `_parse_string()` to recognize
     encoding-prefixed and raw string cores before suffix attachment.

3. Do not edit shared `sphinx.util.cfamily` literal regexes or the C domain.
   - Trace: F4; PO-FRAME-1.
   - Reason: UDL suffixes are C++-specific and should not become accepted by the
     C parser through shared utilities.

4. Do not edit `_parse_operator()`.
   - Trace: E4; PO-FRAME-2.
   - Reason: literal operator declarations were already handled and are not the
     failing expression-literal path.

5. Do not change tests.
   - Trace: task constraints and PROOF.md test recommendation.
   - Reason: the benchmark fixes production code only; tests are fixed/hidden.

## Suggested Future Tests

These are recommendations only; no tests were edited.

- `inline constexpr auto planck_constant = 6.62607015e-34q_J * 1q_s`
- `auto t = 1q_s`
- `auto s = "m"_tag`
- `auto s8 = u8"m"_tag`
- `auto r = R"(m)"_tag`
- `auto c = 'm'_tag`
- `void operator""_tag()`

## Open Limitations

- Universal-character-name suffix spelling is outside this patch's suffix regex.
- Full C++ raw string delimiter validation is not modeled.
- The formal proof is constructed only; run the emitted K commands before using
  it for any test-redundancy decision.
