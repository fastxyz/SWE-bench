# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`,
`kast`, or `kprove` were run.

## Formal artifacts

- `fvk/mini-sympy-string.k` defines a minimal symbolic model of the codegen
  `String` constructor, reconstruction from `.args`, kwargs reconstruction,
  invalid text rejection, and default codegen atom traversal.
- `fvk/sympy-string-spec.k` states K-style claims for PO1 through PO5.

## Proof of PO1 and PO2

Let `C` be `String` or any subclass of `String`, and let `s` be a Python string.

1. `String.__new__` delegates to `Token.__new__`, which validates and stores the
   public slot value `text == s`.
2. V1 then assigns `_args = (Str(obj.text),)`, so the sole positional argument
   is a `Basic` object carrying the same text.
3. `obj.func(*obj.args)` calls `C(Str(s))`.
4. `_construct_text` recognizes `Str` and returns `Str.name`, so the new
   object's public slot is again `text == s`.
5. `Token.__eq__` compares class and slot values; both objects have class `C`
   and `text == s`.
6. Therefore `obj.func(*obj.args) == obj`.

This discharges F1 and avoids F2.

## Proof of PO3

`Token.kwargs()` constructs a dict from slots. Since V1 leaves the `text` slot
as the Python string `s`, `obj.kwargs()` still returns `{"text": s}` and
`obj.func(**obj.kwargs())` follows the ordinary public constructor path. The
result has class `C` and `text == s`, so `Token.__eq__` gives equality.

## Proof of PO4

For a public non-string, non-`Str` value `x`, `_construct_text` does not take
the new `Str` branch and then reaches the existing `not isinstance(x, str)`
check. The same `TypeError` behavior is preserved.

## Proof of PO5

Default codegen atom collection uses `Token.atoms()`:

1. It delegates typed calls `atoms(T)` to `Basic.atoms(T)`, preserving normal
   typed search.
2. For untyped/default traversal, when the traversal reaches a `String`, it
   adds that `String` to the result and calls `skip()`.
3. The skip prevents traversal into the internal `Str(s)` reconstruction
   wrapper.
4. Non-`String` leaf behavior remains the same as generic `Basic.atoms()` for
   codegen tokens: Basic nodes without args are collected.

This discharges F3 without changing global `Basic.atoms()`.

## Adequacy gate

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases each claim and
`fvk/SPEC_AUDIT.md` marks all claims PASS against `fvk/INTENT_SPEC.md`. The
proof therefore covers the full public issue intent: positional reconstruction,
Basic-compatible args, and public compatibility frames.

## Test guidance

No tests were run and no test files were modified. After machine checking and a
normal project test run, public tests that assert only these in-domain
properties may be considered proof-subsumed:

- `_test_args(String(...))`, `_test_args(QuotedString(...))`, and
  `_test_args(Comment(...))`
- kwargs reconstruction for `String`
- default atom-leaf behavior for `sizeof(...)`

This is recommendation-only and conditioned on machine checking; keep the tests
until the K claims and normal test suite are actually run.

## Commands for later machine checking

These commands are emitted for reproducibility and were not executed:

```sh
kompile fvk/mini-sympy-string.k --backend haskell
kast --backend haskell fvk/sympy-string-spec.k
kprove fvk/sympy-string-spec.k
```

Expected machine-check result after a faithful K fragment is accepted:
`kprove` reduces the claims to `#Top`.
