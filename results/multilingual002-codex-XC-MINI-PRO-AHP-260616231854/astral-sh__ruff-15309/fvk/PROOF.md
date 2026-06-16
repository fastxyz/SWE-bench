# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claims

The constructed proof targets the abstract decision predicate in
`fvk/mini-f523-format-fix.k` and the claims in `fvk/f523-format-fix-spec.k`:

1. `shouldDropFormatCall(true, true, true, true, N, N) => true` for `N > 0`.
2. `shouldDropFormatCall(true, false, true, true, N, N) => false` for `N > 0`.
3. `shouldDropFormatCall(true, true, false, true, N, N) => false` for `N > 0`.
4. `shouldDropFormatCall(false, true, true, true, N, N) => false` for `N > 0`.

These claims correspond to PO1 through PO4.

## Constructed Proof Sketch

For claim 1, symbolic execution rewrites `allArgsUnused(N, N)` to true. With
`keywords_empty`, `no_fields`, `literal_identity`, and `nonempty_unused` all
true, the conjunction in `shouldDropFormatCall` rewrites to true. The Rust source
then takes the special branch and returns a range replacement from the full call
range to the receiver range, discharging PO1.

For claim 2, `no_fields` is false. The decision predicate rewrites to false
without consulting the all-arguments fact. The Rust source mirrors this because
the special branch requires `summary.autos.is_empty()`,
`summary.indices.is_empty()`, and `summary.keywords.is_empty()`. Any parsed field
therefore falls through to the CST argument-removal path, discharging PO2.

For claim 3, `literal_identity` is false. The predicate rewrites to false. The
Rust source mirrors this through `summary.is_literal_identity`. A doubled-brace
template such as `"{{}}"` parses to a literal value that differs from the
original string value, so the full call is not dropped. This discharges PO3 and
fixes finding F2.

For claim 4, `keywords_empty` is false. The predicate rewrites to false. The
Rust source mirrors this through `call.arguments.keywords.is_empty()`, so calls
with keyword arguments keep the `.format(...)` operation and use the fallback
argument-removal edit. This discharges PO4.

PO5 is discharged by case analysis on `format_string.format_parts.as_slice()`:
the empty template has no parts and is identity-preserving; a single literal part
is identity-preserving exactly when the parsed literal equals the original
literal value; every other shape either has fields or parser-normalized literal
text and is rejected by the drop branch.

PO6 is discharged by source flow: `strings.rs` computes one `FormatSummary` from
the string literal and passes that same reference to the helper that chooses the
edit. PO7 is discharged because the original `transform_expression` fallback is
the unchanged fallthrough path.

## Machine Check Commands

These commands are intentionally not executed in this session:

```sh
kompile fvk/mini-f523-format-fix.k --backend haskell
kprove fvk/f523-format-fix-spec.k --definition fvk/mini-f523-format-fix-kompiled
```

Expected result after any syntax adjustments required by a local K installation:
`#Top` for all claims.

## Test Guidance

No test files were modified. In a normal development environment, add or keep
tests for:

- `"Hello".format("world")` => `"Hello"`;
- `"{{}}".format(1)` must not be rewritten to `"{{}}"`;
- `"{name}".format("unused")` must not be rewritten to `"{name}"`;
- `"{name}".format("unused", name="world")` should remove only the positional
  argument.

Do not remove existing tests based on this constructed proof unless the emitted
K claims are machine-checked and return `#Top`.
