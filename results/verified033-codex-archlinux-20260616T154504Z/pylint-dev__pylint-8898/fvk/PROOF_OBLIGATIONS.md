# Proof Obligations

Status: constructed, not machine-checked.

O1. Termination / progress:
For any finite input suffix, each scanner iteration consumes exactly one character. The suffix length strictly decreases until finalization.

O2. State update soundness:
For each character class, the scanner updates `escaped`, `in_character_class`, and `open_brace` according to the contract:

- escaped character: append it and clear `escaped`.
- backslash: append it and set `escaped`.
- unescaped `[` outside a class: enter character-class mode.
- unescaped `]` inside a class: leave character-class mode.
- unescaped `{` outside a class: enter brace mode.
- unescaped `}` in brace mode outside a class: leave brace mode.

O3. Separator characterization:
A comma emits the current stripped fragment and resets the current fragment if and only if it is unescaped, outside a character class, and outside brace mode.

O4. Preservation and ordering:
Every character that is not a separator is appended to the current fragment exactly once. Emitted fragments preserve left-to-right input order.

O5. Legacy CSV trimming:
When a fragment is emitted, it is stripped; empty stripped fragments are discarded. This matches `_splitstrip` behavior for repeated, leading, or trailing separators.

O6. Reported quantifier example:
For `(foo{1,3})`, the comma is scanned with `open_brace == True`; the output is exactly one fragment, `(foo{1,3})`.

O7. Backward-compatible list example:
For `foo,bar`, the comma is scanned with all context flags false; the output is exactly `["foo", "bar"]`.

O8. Transformer map:
If `_split_regex_csv(value) == [f1, ..., fn]` and every `fi` is a valid regex, `_regexp_csv_transfomer(value)` returns `[re.compile(f1), ..., re.compile(fn)]` in order.

O9. Transformer error:
If any split fragment is invalid, the transformer raises `argparse.ArgumentTypeError` through `_regex_transformer`, preserving the clean error path.

O10. Frame conditions:
No non-regex CSV transformer, path CSV transformer, option key, or public return shape changes.
