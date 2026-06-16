# FVK Spec

Status: constructed, not machine-checked.

## Scope

This specification covers the behavior changed by V1:

- `_split_regex_csv(value: str) -> Sequence[str]`
- `_regexp_csv_transfomer(value: str) -> Sequence[Pattern[str]]`

The parser is modeled as a finite-state scan over the input characters. The regex compiler itself is abstracted as `compileRegex(fragment)`, with a public side condition `isValidRegex(fragment)`; the issue is about whether the correct fragments reach compilation, not about Python's `re` semantics.

## Public Intent Ledger

The full ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. Critical obligations:

- E1/E2/E5: `(foo{1,3})` must be one fragment.
- E3: `\,` must be available as an escaped literal comma.
- E4/E6: top-level unescaped commas still separate regex entries.
- E7: invalid fragments report `argparse.ArgumentTypeError`.
- E8: the existing public test that expects an error for `(foo{1,3})` is SUSPECT legacy behavior and cannot veto the issue intent.

## Contract: `_split_regex_csv`

Domain: all finite Python strings.

State variables:

- `pattern`: the current output fragment under construction.
- `patterns`: the ordered list of emitted fragments.
- `escaped`: true immediately after an unescaped backslash has been appended.
- `in_character_class`: true after an unescaped `[` until the matching unescaped `]`.
- `open_brace`: true after an unescaped `{` outside a character class until an unescaped `}` outside a character class.

Separator definition:

- A comma is a separator exactly when `escaped == False`, `in_character_class == False`, and `open_brace == False`.

Postcondition:

- The return value is the ordered sequence of non-empty, stripped fragments obtained by removing separator commas as defined above.
- Every non-separator character is preserved in its original relative order in exactly one output fragment.
- A comma inside `{...}`, inside `[...]`, or immediately escaped by an odd-length run of backslashes is preserved as part of the current fragment.
- Empty fragments created by repeated or leading/trailing separators are discarded, matching the existing `_splitstrip` behavior used by generic CSV parsing.

## Contract: `_regexp_csv_transfomer`

Domain: all finite Python strings.

Postconditions:

- Let `fragments = _split_regex_csv(value)`.
- If every `fragment` is a valid Python regular expression, return `[re.compile(fragment) for fragment in fragments]` in the same order.
- If any `fragment` is invalid, raise `argparse.ArgumentTypeError` using `_regex_transformer`; do not leak a raw `re.error` traceback.

Frame conditions:

- `_csv_transformer`, `_glob_paths_csv_transformer`, `_regexp_paths_csv_transfomer`, and other argument type transformers are unchanged.
- The `"regexp_csv"` type key and `_regexp_csv_transfomer` return shape remain unchanged.

## Formal Core

Formal fragment files:

- `fvk/mini-regex-csv.k`
- `fvk/regex-csv-spec.k`

Machine-check commands to run later:

```sh
kompile fvk/mini-regex-csv.k --backend haskell
kast --backend haskell fvk/regex-csv-spec.k
kprove fvk/regex-csv-spec.k
```

Expected result if machine-checked: `#Top` for all claims.
