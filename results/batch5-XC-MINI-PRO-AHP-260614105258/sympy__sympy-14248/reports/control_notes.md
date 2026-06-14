# Control notes — sympy__sympy-14248 (V2, post-review)

This documents every decision made after the code review in
`review/FINDINGS.md`. Two source edits were made; everything else in V1 was
confirmed and left unchanged. Each decision is traced to numbered findings.

## Summary of the review conclusion

V1 already fixes the reported issue correctly in all three printers
(finding **F9**): `A - A*B - B` and `A - B` render with proper signs and no
`(-1)*` / `+ -1` artifacts. The review surfaced two genuine *edge-case
regressions* (V1 made a previously-working input misbehave) — **F1** (a crash)
and **F2** (a dropped operator) — both of which are now fixed. The remaining
findings (**F3–F8**) are either explanatory or low-severity cosmetic items that
were deliberately left as-is.

## Changes made

### Change 1 — `sympy/printing/str.py`, `_print_MatMul` (addresses F1)

`if c.is_number and c < 0:` → `if c.is_number and c.is_negative:`

Per **F1**, `as_coeff_mmul()` can return a non-real coefficient (e.g. `I` for
`I*A`); `c.is_number` is then `True`, so V1 evaluated `c < 0`, and `I < 0`
raises `TypeError` (`core/expr.py:332-334`) — so `str(I*A)` crashed under V1,
though the original code printed `I*A`. `c.is_negative` is a pure assumption
query that never raises and equals `c < 0` for every real number, so:
- output is **identical** to V1 for all real coefficients — every visible test,
  and the issue's `-1`/`-2` cases (verified: `-B`, `-2*B`, `-A*B` unchanged);
- the crash on `I*A` / NaN coefficients is removed (regression fixed).

This is the minimal change that fixes F1 without altering any in-scope output.

### Change 2 — `sympy/printing/pretty/pretty.py`, `_print_MatAdd` (addresses F2)

```python
coeff = S(item.args[0])
if coeff.is_number and coeff.is_negative:
```
(was `if S(item.args[0]).is_negative:`)

Per **F2**, the bare-space separator branch assumes a negative term prints with
its own leading `-`. That is only true for negative *number* coefficients; a
negative *symbol* coefficient (`Symbol('n', negative=True)`) satisfies
`is_negative` yet prints as `n⋅B` with no leading `-`, so when such a term is not
the first element V1 produced operator-less output like `A⋅C n⋅B` (the original
`_print_seq` always emitted `' + '`, giving the correct `A⋅C + n⋅B`). Restricting the test to negative
*numbers* with `is_number` restores `+` for symbolic coefficients (matching the
original) while preserving the `-` handling for the numeric coefficients the
issue targets. Per **F3**, this aligns pretty's coefficient-based detection with
the rendered-form semantics that str/latex already use. The change is
output-identical to V1 for every numeric coefficient, so:
- `A - B → -B + A` and `test_MatrixElement_printing` (`"(-B + A)[0, 0]"`) are
  unchanged (the negative term is first and emitted as-is);
- `test_Adjoint` (`Adjoint(X) + Adjoint(Y)`) is unchanged (`Adjoint` is not a
  `MatMul`; `is_number` is `False` for its arg → `+`, as before).

`S(...)` (sympify) is kept rather than switching to `item.is_MatMul and
item.args[0]...` because `S(...)` is robust for every possible `MatAdd` term
(including a `MatrixSymbol` whose `args[0]` is a bare name string), so the fix
is minimal and cannot raise `AttributeError`.

## Decisions to leave V1 unchanged

- **F3** (detection mechanism differs across printers): no separate action; the
  Change-2 `is_number` guard is exactly what brings pretty into line. str/latex
  already use the correct printed-string test, so they need nothing.
- **F4** (pretty uses `" "` where str/latex use `" - "`): left as-is. All
  outputs are correct and unambiguous; emitting `" - "` in pretty would require
  re-printing each negative term's positive 2-D form (à la `_print_Add`'s
  `pretty_negative`), a disproportionate rewrite for a cosmetic gain.
- **F5** (latex double space before an irrational coefficient in non-first
  position): left as-is — invisible in rendered LaTeX and consistent with the
  scalar `_print_Add` `t = t[1:]` idiom; no test exercises it.
- **F6** (str `-(1/2)*A` vs original `(-1/2)*A`): left as-is — both valid, not a
  regression, and `_print_MatMul` never did fraction folding.
- **F7** (str `_print_MatAdd` dead `precedence < PREC` parens branch): left
  as-is — kept intentionally to mirror `_print_Add`'s structure; never fires for
  matrix terms, so it is harmless.
- **F8** (ordering dependence): no action — the fix does not change ordering, and
  `default_sort_key`'s MatMul-before-MatrixSymbol ordering (confirmed by the
  issue output and `test_matAdd`) is what makes the negative-first cases render
  into the asserted sets.

## Net effect

- Issue behaviour: unchanged from V1 (correct) — **F9**.
- `str(I*A)` / NaN-coefficient `MatMul`: no longer crashes — **F1**.
- `pprint` of a `MatAdd` with a negative-symbol coefficient: operator restored —
  **F2**.
- All visible tests and source doctests: outputs unchanged by both edits.
