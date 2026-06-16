# FVK Spec: sympy__sympy-20916

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited behavior is the implicit trailing-digit subscript rule implemented
by `sympy.printing.conventions.split_super_sub` and consumed by unicode pretty
printing through `pretty_symbol`. The source change under audit is:

```python
_name_with_digits_p = re.compile(r'^([^\W\d_]+)([0-9]+)$')
```

This FVK pass does not respecify all of SymPy's pretty-printer behavior. It
specifies the observable issue family: symbol names whose first name part is a
letter-like Unicode word run followed by ASCII decimal digits.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| I1 | prompt | "pprint unicode does not format subscripts on Greek letters" | Unicode pretty output must render the trailing digit of a Greek-letter symbol name as a subscript. | Encoded in S1, S4 |
| I2 | prompt | `sp.pprint(w) # -> [w₀, ...]` and `sp.pprint(ω) # -> [ω0, ...]` | Actual Unicode Greek names such as `ω0` should behave like Latin `w0`. | Encoded in S1, S4 |
| I3 | prompt hint | "regular expression in sympy/printing/conventions.py ... using `[a-zA-Z]` but it should be using `\w` so that it matches Unicode word characters" | The implicit digit rule must admit non-ASCII Unicode word characters in the base part. | Encoded in S1 |
| I4 | public tests | `upretty(Symbol('beta12')) == 'β₁₂'`, `latex(Symbol('q21')) == r"q_{21}"` | Existing ASCII letter plus multi-digit suffix behavior must be preserved. | Encoded in S2 |
| I5 | public tests | `split_super_sub("x_a_b") == ("x", [], ["a", "b"])` and related underscore/caret cases | Explicit `_`, `^`, and `__` separator behavior must remain unchanged. | Encoded in S3 |
| I6 | implementation | `pretty_symbol` converts subscript strings using the `sub` digit table. | Once `split_super_sub` returns `["0"]`, unicode pretty printing can render `₀`. | Used in proof only |

## Definitions

Let `AsciiDigit(c)` mean `c` is one of `0` through `9`.

Let `BaseChar(c)` mean Python regular-expression `\w` matches `c`, while
Python regular-expression `\d` does not match `c`, and `c != "_"`.

Let `BaseRun(B)` mean `B` is a non-empty sequence of `BaseChar` characters.

Let `DigitRun(D)` mean `D` is a non-empty sequence of `AsciiDigit` characters.

In Python 3 regular expression semantics, `BaseRun` is exactly the character
class `[^\W\d_]+`, and `DigitRun` is `[0-9]+`.

## Spec Clauses

S1. For any first name part `N = B + D` where `BaseRun(B)` and `DigitRun(D)`,
`split_super_sub(N)` returns `(B, [], [D])`.

S2. For ASCII Latin bases, S1 preserves the old multi-digit suffix behavior:
`split_super_sub("x10")` is specified as `("x", [], ["10"])`, not
`("x1", [], ["0"])`.

S3. Explicit separator parsing is unchanged. If the existing scan recognizes
`_`, `^`, or `__` as separators, those separators are handled before the
implicit trailing-digit rule is applied to the first name part. Leading
underscore names are not broadened by this spec.

S4. For unicode pretty printing, if `split_super_sub` returns `(B, [], [D])`
and every character in `D` is in the `sub` digit table, `pretty_symbol(B + D)`
renders the base text followed by the corresponding Unicode subscript digits.
For the motivating case, `pretty_symbol("ω0")` is specified to render `ω₀`.

S5. Public API compatibility is preserved: `split_super_sub(text)` continues to
return `(name, supers, subs)` and no caller signature changes.

## Formal Core

The constructed formal core is in:

- `fvk/mini-symbol-conventions.k`
- `fvk/symbol-conventions-spec.k`

It models only the property-bearing fragment: a first name part, the
Unicode-word-minus-digit-minus-underscore base class, an ASCII digit suffix,
and the split/no-split result.

## Commands Not Executed

The following are the commands to machine-check this constructed proof later.
They were not run in this benchmark session:

```sh
cd fvk
kompile mini-symbol-conventions.k --backend haskell
kast --backend haskell symbol-conventions-spec.k
kprove symbol-conventions-spec.k
```
