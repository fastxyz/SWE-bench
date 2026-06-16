# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## What Is Proved

The constructed proof covers partial correctness of the C++ literal parser
transition for recognized numeric, string, and character literal cores:

- With an immediate valid UDL suffix, the suffix is attached to the literal AST
  and consumed from the input.
- Without an immediate valid UDL suffix, the existing literal behavior is
  preserved.
- Rendering and signature description preserve `core + suffix`.

## Proof Sketch

### Numeric Path

1. `_parse_literal()` reaches the numeric regex loop.
2. The existing numeric regex consumes the literal core, such as
   `6.62607015e-34` or `1`.
3. The existing built-in suffix loop consumes any built-in suffix characters
   exactly as before.
4. `_parse_user_defined_literal()` calls
   `_parse_user_defined_literal_suffix()`.
5. If `_udl_suffix_re` matches, `BaseParser.match()` advances `self.pos` to the
   end of the suffix and stores the suffix in `matched_text`.
6. `ASTUserDefinedLiteral(ASTNumberLiteral(core), suffix)` is returned.
7. `_stringify()` and `describe_signature()` concatenate the base literal
   spelling and suffix, while the parser position now points at the following
   input. In the reported example, that following input is the `*` operator.

This discharges PO-NUM-1 and PO-RENDER-1.

### String Path

1. `_parse_string()` records `startPos`.
2. It consumes an optional encoding prefix `u8`, `u`, `U`, or `L` only when that
   prefix is followed by `"` or `R`, preserving non-string identifiers.
3. If the core is raw string spelling, `_parse_string()` scans to the matching
   raw terminator and returns the entire raw string core.
4. Otherwise it uses the existing escaped-quote loop for ordinary string bodies.
5. `_parse_literal()` wraps `ASTStringLiteral(core)` with
   `ASTUserDefinedLiteral` when a valid suffix follows.

This discharges PO-STR-1, PO-STR-2, and PO-RENDER-1.

### Character Path

1. `_parse_literal()` matches `char_literal_re`.
2. `ASTCharLiteral(prefix, data)` is constructed exactly as before, so character
   decoding is unaffected.
3. `_parse_user_defined_literal()` attaches any immediate suffix outside the
   character node.

This discharges PO-CHAR-1 and PO-RENDER-1.

### No-Suffix Frame

If `_udl_suffix_re` does not match, `_parse_user_defined_literal()` returns the
original base literal unchanged. This discharges PO-NUM-2 for numeric literals
and the corresponding no-suffix frame for string and character literals.

### Compatibility Frame

The diff is limited to `repo/sphinx/domains/cpp.py`; `sphinx.util.cfamily`,
`repo/sphinx/domains/c.py`, and `_parse_operator()` are untouched. This
discharges PO-FRAME-1 and PO-FRAME-2.

## K Proof Core

The K model abstracts the parser state to:

```text
parse(kind, core, suffix, rest)
```

The post-state is:

```text
parsed(kind, core + suffix, suffix, rest)
```

for valid suffixes, and:

```text
parsed(kind, core, "", rest)
```

when no suffix exists. The observable includes both rendered spelling and
remaining input, so the abstraction distinguishes the pre-fix failure
(`rest` starts with `q_J`) from the fixed behavior (`rest` starts with `*`).

Exact commands, not executed:

```sh
kompile fvk/mini-cpp-literals.k --backend haskell
kast --backend haskell fvk/cpp-udl-spec.k
kprove fvk/cpp-udl-spec.k
```

Expected result: `#Top`.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics models the relevant parser transition rather than full
  Python execution.
- Suffixes are limited to the existing ASCII identifier scope.
- Termination is not separately proved; the string scans are finite-state scans
  over the bounded input string and this pass targets partial correctness.

## Test Recommendation

Do not remove tests. After machine-checking, add or keep tests covering:

- the reported numeric expression;
- integer UDL suffixes;
- ordinary, prefixed, and raw string UDL suffixes;
- character UDL suffixes;
- existing `operator""` declarations.
