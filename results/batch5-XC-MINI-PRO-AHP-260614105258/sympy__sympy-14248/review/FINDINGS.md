# Code review — sympy__sympy-14248 V1 fix

Scope reviewed: the V1 edits to `_print_MatMul`/`_print_MatAdd` in
`sympy/printing/str.py`, `sympy/printing/latex.py`, and
`sympy/printing/pretty/pretty.py`. No execution available; all behaviour is
reasoned from the source.

Severity legend: **High** = breaks the issue or a common case; **Medium** =
real regression on a valid but uncommon input; **Low** = cosmetic / no behaviour
change.

---

## F1 — str `_print_MatMul`: `c < 0` raises on a non-real numeric coefficient (Medium, regression)

`str.py:308`:
```python
c, m = expr.as_coeff_mmul()
if c.is_number and c < 0:
```

`as_coeff_mmul()` returns the *full* scalar coefficient, which can be non-real.
For `I*A` (`A` a `MatrixSymbol`), `c = I`. `ImaginaryUnit.is_number` is `True`
(`core/numbers.py:3767`), so the guard proceeds to evaluate `c < 0`, i.e.
`I < 0`. `Expr.__lt__` (`core/expr.py:332-334`) does:
```python
for me in (self, other):
    if me.is_complex and me.is_real is False:
        raise TypeError("Invalid comparison of complex %s" % me)
```
so `I < 0` **raises `TypeError`**. `S.NaN < 0` likewise raises
(`core/expr.py:335-336`).

Therefore `str(I*A)` raises under V1, whereas the *original* pre-fix
`_print_MatMul` printed it fine as `I*A`. This is a regression: V1 turns a
previously-working print into a crash.

For every *real* number `c`, `c.is_negative` is `True` exactly when `c < 0`, so
replacing the guard with `c.is_number and c.is_negative` is output-identical on
all in-scope (real) coefficients — including every visible test and the issue's
`-1`/`-2` cases — while being crash-free (`is_negative` returns `False`/`None`
for non-reals and NaN and never raises).

**Action:** change `c.is_number and c < 0` → `c.is_number and c.is_negative`.

---

## F2 — pretty `_print_MatAdd`: negative-*symbol* coefficient drops the operator (Medium, regression)

`pretty.py:828`:
```python
if S(item.args[0]).is_negative:
    s = prettyForm(*stringPict.next(s, ' '))   # bare-space separator
    pform = self._print(item)
else:
    s = prettyForm(*stringPict.next(s, ' + '))
```

The intent is: when a *following* term is negative, use a bare `' '` separator
and let the term supply its own leading `-`. That assumption only holds when the
term actually *prints* with a leading minus, i.e. when its coefficient is a
negative **number**. For a negative **symbol** coefficient
(`n = Symbol('n', negative=True)`), `S(n).is_negative` is `True`, but
`MatMul(n, B)` pretty-prints as `n⋅B` (a symbol never renders a leading `-`;
`prettyForm.__mul__` only substitutes `-1 → -` and checks `result[0][0] == '-'`).

Concretely, whenever such a term is **not** the first element of the `MatAdd`
(e.g. a second `MatMul` term with a negative-symbol coefficient, as in
`A*C + n*B`), V1 emits the bare-space branch and the pform carries no `-`, so the
result reads like `A⋅C n⋅B` — the `+`/`-` operator is **missing** entirely. The
original `_print_seq(expr.args, None, None, ' + ')` always emitted `' + '` and so
produced the correct `A⋅C + n⋅B`; this is a regression introduced by V1.
(Whether a given literal triggers it depends on `default_sort_key` placing the
negative-symbol term after another term; the logic flaw — treating a
negative-symbol coefficient as if it self-signs — is independent of ordering.)

(The single-negative-first cases that visible tests exercise —
`A - B → -B + A`, `test_MatrixElement_printing` — are unaffected, because the
negative term is the *first* element and is emitted as-is regardless.)

The correct discriminator is "the coefficient is a negative *number*", matching
when the pform actually shows a leading `-`. Adding an `is_number` guard
(`coeff.is_number and coeff.is_negative`) restores `+` for negative-symbol /
symbolic coefficients (matching the original) while keeping the `-` handling for
numeric coefficients (the issue's target). It is output-identical to V1 for
every numeric coefficient.

**Action:** compute `coeff = S(item.args[0])` once and guard with
`coeff.is_number and coeff.is_negative`.

---

## F3 — Detection mechanism differs across printers (Low, explains F2; no extra action)

str (`str.py:327`) and latex (`latex.py:1483`) decide a term's sign from its
*printed string* (`t.startswith('-')`). That is the semantically right test: it
asks "does the rendered term begin with a minus we can pull out". As a result
str/latex are already correct for negative-symbol coefficients
(`MatMul(n,B)` prints `n*B` / `n B`, no leading `-`, so they use `+`), and for
`MatMul(-x, A)` latex even pulls the sign nicely (`- x A`). pretty cannot easily
inspect a 2-D `prettyForm`, so it inspects the coefficient instead — which is
why F2 is pretty-only. The F2 fix narrows pretty's coefficient test to negative
*numbers*, bringing it into line with the rendered-form semantics for all
realistic terms. No change beyond F2.

---

## F4 — Cross-printer style difference for internal negatives (Low, accepted)

For `A - A*B - B` the three printers yield:
- str:   `-B - A*B + A`   (strip-and-rejoin → ` - ` separators)
- latex: `-B - A B + A`   (strip-and-rejoin → ` - ` separators)
- pretty: `-B -A⋅B + A`   (bare-space + term keeps its own `-`)

All are correct (the issue — a `(-1)`/`+ -1` rendering — is gone in every case).
Making pretty emit ` - ` would require re-printing each negative term's positive
form (as `_print_Add`'s `pretty_negative` does) — a larger rewrite for a purely
stylistic gain, and the bare-space form is unambiguous. Accepted; no action.

---

## F5 — latex `_print_MatAdd` leaves a double space for irrational coefficients (Low, accepted)

`t = t[1:]` strips only the first character. `MatMul(-sqrt(2), A)` prints as
`- \sqrt{2} A`, so stripping yields a leading-space `" \sqrt{2} A"`; when such a
term is *not* first, the join produces `... -  \sqrt{2} A` (two spaces). This is
invisible in rendered LaTeX (math-mode collapses spaces) and mirrors the scalar
`_print_Add` idiom (`t = t[1:]`). No visible test exercises an irrational
coefficient inside a `MatAdd`. Accepted; no action.

---

## F6 — str `_print_MatMul` fraction rendering changes cosmetically (Low, accepted)

`MatMul(Rational(-1,2), A)` now prints `-(1/2)*A` (sign folded out via
`_keep_coeff`) vs the original `(-1/2)*A`. Both are valid; `_print_MatMul` has
never done numerator/denominator folding like `_print_Mul`. Not a regression.
Accepted; no action.

---

## F7 — str `_print_MatAdd` keeps a never-triggered parens branch (Low, intentional)

```python
if precedence(term) < PREC:
    l.extend([sign, "(%s)" % t])
```
`PREC = precedence(MatAdd) = 40`; every term that can appear in a flattened
`MatAdd` (`MatMul`=50, `MatrixSymbol`=Atom, `MatPow`/`Transpose`/`Inverse`=60,
nested `MatAdd`=40) has precedence ≥ 40, so the branch never fires. It is kept
deliberately to mirror `_print_Add` (same structure/idiom). Harmless; no action.

---

## F8 — Correctness depends on `MatAdd` term ordering (Low, documented)

The visible `test_matAdd` cases (`C - 2*B`, …) and the issue's own output show
`MatAdd` sorts `MatMul` terms before bare `MatrixSymbol`s, so the negative terms
land first; with that ordering the strip-and-rejoin (str/latex) yields outputs
in the asserted sets (`'-2 B + C'`, etc.). The fix does not alter ordering, and
the ordering is a stable property of `default_sort_key`. Documented; no action.

---

## F9 — Core issue is fixed by V1 (confirmation)

`A - A*B - B` renders as `-B - A*B + A` (str), `-B - A B + A` (latex),
`-B -A⋅B + A` (pretty); `A - B` renders as `-B + A` in all three — exactly the
behaviour the issue asks for, with no surviving `(-1)*`/`+ -1`. The pre-fix
`test_MatrixElement_printing` in `test_str.py`/`test_latex.py` still asserts the
*old* buggy strings and will be replaced by the evaluation's test patch; the
already-clean pretty assertion (`"(-B + A)[0, 0]"`) is reproduced unchanged.
V1's central design is sound; only the F1/F2 edge cases need correcting.
