# Formal Spec English

Status: paraphrase of the K claims; constructed, not machine-checked.

Claims in `fvk/regex-csv-spec.k` mean:

- `REGEX-TOPLEVEL-CSV`: Given a top-level comma between `foo` and `bar`, the scanner emits two fragments, `foo` and `bar`, preserving legacy CSV list behavior.
- `REGEX-QUANTIFIER-EXAMPLE`: Given `(foo{1,3})`, the comma is scanned while `open_brace` is true, so the whole input is emitted as one fragment.
- `REGEX-ESCAPED-COMMA`: Given `foo\,bar`, the comma is scanned while `escaped` is true, so it stays inside the fragment.
- `REGEX-CHARCLASS-COMMA`: Given `[a,b]`, the comma is scanned while `in_character_class` is true, so it stays inside the fragment.
- `REGEX-TRANSFORMER-MAP`: For any input whose split fragments are valid regexes, `_regexp_csv_transfomer` compiles every fragment in order and returns that ordered sequence.
- `REGEX-TRANSFORMER-ERROR`: If a split fragment is not a valid regex, `_regexp_csv_transfomer` reaches the `_regex_transformer` error branch and raises `argparse.ArgumentTypeError`.

The claims are partial-correctness claims over the scanner. The loop is over a finite input suffix and has a decreasing suffix-length measure, so termination is straightforward but not machine-checked in this run.
