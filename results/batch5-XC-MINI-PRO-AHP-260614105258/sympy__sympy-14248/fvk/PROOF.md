# PROOF.md — constructed correctness proof for sympy-14248 (V2)

**CONSTRUCTED, NOT MACHINE-CHECKED.** The proof is symbolic execution against the
mini-X fragment [`matprint.k`](matprint.k) discharging the claims in
[`matprint-spec.k`](matprint-spec.k). Run-commands at the end. Obligations in
[`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md).

---

## 1. What is proved, in one breath

For every non-empty list of term-strings `SS`, `_print_MatAdd` returns
`render(SS)` — the standard signed sum where each term carries its own sign and
no `"+ -"` ever appears (PO-ADD-*). For every MatMul, `_print_MatMul` returns
(no crash, PO-MM-TOTAL **in V2**) and begins with `-` iff the coefficient is a
negative number, with a BODY that never begins with `-` (PO-MM-SIGN) — exactly
the precondition the MatAdd render relies on.

---

## 2. (LOOP) circularity and (MATADD) contract

**Claim (LOOP).** `⟨#loop⟩ ⟨terms TS ⇒ .List⟩ ⟨l LACC ⇒ LACC ++ appendPairs(TS)⟩`.

*Proof by guarded coinduction on `TS`* (the loop is structural over the finite
`<terms>` list; the genuine `=>⁺` step that earns the hypothesis is one loop
rewrite):

- **Case `TS = .List`** (exit): rule `#loop ⇒ #assemble` with `<terms> .List`
  fires; `appendPairs(.List) = .List`, so `l` is unchanged. Reflexivity closes
  it. (This is the zero-progress *exit* branch; guardedness is satisfied because
  it does not invoke the hypothesis.)
- **Case `TS = ListItem(S) TS'`** (body): one of the two `#loop` rules fires —
  by **Case Analysis** on `isNeg(S)`:
  - `isNeg(S)` true: `<l>` gains `ListItem("-") ListItem(tail(S))` =
    `ListItem(sgOf(S)) ListItem(bodyOf(S))`;
  - `isNeg(S)` false: `<l>` gains `ListItem("+") ListItem(S)` =
    `ListItem(sgOf(S)) ListItem(bodyOf(S))`.
  `<terms>` shrinks to `TS'`. That is one genuine step ⇒ **invoke (LOOP)** on the
  shifted state `⟨terms TS'⟩ ⟨l (LACC ++ [sgOf(S),bodyOf(S)])⟩`. The hypothesis
  gives `l ⇒ LACC ++ [sgOf(S),bodyOf(S)] ++ appendPairs(TS')`. By the
  `appendPairs` definition this equals `LACC ++ appendPairs(TS)`. ∎

**Claim (MATADD).** `printMatAdd(SS) ⇒ .K` with `⟨res ⇒ render(SS)⟩`,
`requires SS =/= .Strings`.

*Proof by Transitivity:*
1. **Axiom** (load): `printMatAdd(SS) ⇒ #loop` with `<terms> = strs2list(SS)`,
   `<l> = .List`.
2. **(LOOP) as a lemma** at entry `LACC = .List`, `TS = strs2list(SS)`:
   reaches `#assemble` with `<l> = appendPairs(strs2list(SS))
   = [sgOf(s_0),bodyOf(s_0), …, sgOf(s_{n-1}),bodyOf(s_{n-1})]`.
3. **Axiom** (assemble): since `SS ≠ .Strings`, `n ≥ 1`, so `<l>` is non-empty
   and matches `ListItem(SG0) REST`. The rule pops `SG0 = sgOf(s_0)` and sets
   `<res> = #head(SG0) +String joinSp(REST)`.
4. **Consequence (VC-RENDER).** Show `#head(sgOf(s_0)) +String joinSp(REST)
   = render(SS)`. `REST = [bodyOf(s_0), sgOf(s_1),bodyOf(s_1), …]`, and `joinSp`
   inserts single spaces, giving
   `bodyOf(s_0) + " " + sgOf(s_1) + " " + bodyOf(s_1) + …` =
   `renderTail(s_0,…,s_{n-1})` by definition. Prepending `#head(sgOf(s_0))`
   matches `render`. This is a pure STRING/`+String` identity (associativity of
   `+String`, definition unfolding) — discharged structurally, no SMT needed. ∎

**Corollary (PO-ADD-NOPLUSNEG).** In `render(SS)`, a term `s_i` (`i ≥ 1`) appears
as `… +String " " +String sgOf(s_i) +String " " +String bodyOf(s_i)`. If `s_i`
is negative, `sgOf(s_i) = "-"` and `bodyOf(s_i) = s_i[1:]` (the `-` removed), so
the rendered fragment is `" - " + s_i[1:]`, **never** `" + " + s_i` (which would
be `" + -…"`). The buggy pattern is provably absent. ∎

This proof is **shape-identical for T2 (str) and T3 (latex)** — same algorithm,
same fragment; the alphabet of `bodyOf` differs (`*` vs space joins) but the loop
and assembly are the same rules.

---

## 3. (MATMUL) sign-fold — PO-MM-SIGN

`printMatMul(c, BODY)` where `BODY` is the `*`-join of the sign-folded factors.

- **`c = neg`** (negative number): rule ⇒ `"-" +String BODY`. Begins with `-`. ✓
- **`c ∈ {nonneg, nonreal, sym}`**: rule ⇒ `BODY`. Must show `BODY` does not
  begin with `-`. `BODY = parenthesize(f_0) *…* parenthesize(f_k)` where, after
  `_keep_coeff(-c,m)` (when `c=neg`) or unchanged (otherwise), the leading factor
  `f_0` is either a **non-negative** number (prints as a digit / `\sqrt…` / etc.)
  or a matrix factor (`MatrixSymbol`, `MatPow`, …) — none of which begin with `-`
  in str. So `BODY[0] ≠ '-'`. ✓ (Trusted-base lemma L1, see §7.)

Hence **output begins with `-` iff `c` is a negative number** = PO-MM-SIGN. This
is exactly the precondition the (MATADD) corollary uses to classify a MatMul
term, so the two proofs compose: a `MatMul(-1,B)` term prints `-B`, the MatAdd
loop sees `isNeg = true`, emits a `-` separator. ∎

---

## 4. PO-MM-TOTAL — the V1 failure and the V2 fix

**V1** guard: `if c.is_number and c < 0:`.

Symbolically, the four coefficient cases drive the guard:
- `neg`, `nonneg`: `c < 0` is a defined Bool ⇒ a rule fires. ✓
- `sym`: `c.is_number` is `False` ⇒ short-circuit ⇒ `else` ⇒ fires. ✓
- **`nonreal`** (e.g. `I`): `c.is_number` is `True`, so `c < 0` is forced; but
  `I < 0` is **undefined** — in K terms there is **no rewrite** for the guard
  (the side condition aborts), so the configuration is **stuck**. The (MATMUL)
  claim `printMatMul(nonreal, BODY) ⇒ BODY` has **no derivation** under V1.
  ⇒ **PO-MM-TOTAL fails.** Concretely: `str(I*A)` raises `TypeError`.

**V2** guard: `if c.is_number and c.is_negative:`.
- `neg`: `is_number ∧ is_negative` ⇒ `"-" +String BODY`. ✓
- `nonneg`: `is_negative = False` ⇒ `else`. ✓
- `nonreal`: `is_number = True`, `is_negative = False` (a non-real number is not a
  *negative real*) ⇒ `else` ⇒ `BODY`. **A rule fires — no stuck state.** ✓
- `sym`: `is_number = False` ⇒ `else`. ✓

All four cases reduce ⇒ **PO-MM-TOTAL holds in V2.**

**Equivalence on the in-scope domain (no regression).** For every **real**
number `c`, `c.is_negative ≡ (c < 0)` (a real number is `is_negative` exactly
when it is `< 0`; `is_negative` is never `None` for a concrete real). Therefore on
`{neg, nonneg}` ∪ `{sym}` the V2 branch chosen is identical to V1's, so PO-MM-SIGN
and every PO-REG-* output is **byte-for-byte unchanged**. The change only adds a
defined result on the previously-stuck `nonreal` case. ∎ (Discharges FINDING F1.)

---

## 5. T4 (latex MatMul) and the regression suite

- **PO-MM4-NEG1 / PO-MM4-TOTAL.** `args[0] == -1` is a total equality test
  (sympy `__eq__` returns `False` on incomparable operands, never raises). When
  it holds, output `= "-" +String join(args[1:])`; the joined matrix factors do
  not begin with `-` (L1) ⇒ output begins with a single `-`. When it does not
  hold, output `= join(args)` = the pre-fix string verbatim. So `-2 A`,
  `- \sqrt 2 A`, `2 A`, `2 x A`, `1.5 A`, `\sqrt 2 A`, `2 \sqrt 2 x A`,
  `-2 A (…)` are all unchanged (PO-REG-MM), and `MatMul(-1,B) ⇒ -B`,
  `MatMul(-1,A,B) ⇒ -A B`. ✓
- **PO-REG-2XY.** `printMatMul(nonneg, "(X + Y)")`-shape: `c=2` is `nonneg`
  ⇒ `else` ⇒ `BODY = "2*(X + Y)"` (inner MatAdd parenthesised by the unchanged
  `parenthesize`). ✓
- **PO-REG-ADD.** For the canonical ordering (PO-ORDER) each `test_matAdd` case
  has its MatMul term first; e.g. `C-2*B = [MatMul(-2,B), C]` ⇒
  `render = "-" + "2 B" + " " + "+" + " " + "C" = "-2 B + C" ∈ {…}`. The other
  three are the same shape. ✓

## 6. T5 (pretty) — PO-PRETTY-SEP / PO-REG-EL

The pretty loop is the (MATADD) algorithm with the separator chosen by
`S(item.args[0]).is_negative` instead of a string prefix, and the term supplying
its own `-` (the `prettyForm.__mul__` `-1→-` substitution gives `MatMul(-1,B) ⇒
-B` already). For `A - B = MatAdd(MatMul(-1,B), A)` (PO-ORDER):
- first item `MatMul(-1,B)`: `s = -B` (set as `s`, no separator yet);
- item `A`: `S('A').is_negative = None` (falsy) ⇒ `' + '` ⇒ `-B + A`.
⇒ `(A-B)[0,0]` prints `(-B + A)[0, 0]` = the **pre-existing, unchanged**
`test_MatrixElement_printing` expectation (PO-REG-EL). That a *separately
written, already-passing* test matches the model is independent corroboration
that the pretty model is faithful. ✓ (Discharges P3 / FINDING F3 in-domain.)

## 7. Trusted base & residual risk

- **L1 (matrix factors don't lead with `-`).** Trusted: for any matrix factor
  `f` (MatrixSymbol, MatPow, Transpose, Inverse, Identity, ZeroMatrix, explicit
  matrix) `self._print(f)` does not begin with `-` in str/latex. Justification:
  names are identifiers; `**`,`.T`,`^-1`,`I`,`0`,`Matrix([…])`,`\mathbb{…}` all
  begin with a non-`-` char. (A *negative coefficient* is the only `-` source, and
  it is pulled out by the sign fold.)
- **Mini-X adequacy.** The fragment models CPython `str`/`list` ops (`+`, slice,
  `startswith`, `pop(0)`, `join`) and the coefficient trichotomy; it abstracts
  sympy's object graph. Adequacy of that abstraction is trusted.
- **Partial correctness.** Termination is immediate here (the loop is structural
  over a finite list — it strictly consumes `<terms>`), so total correctness
  actually also holds; but per FVK default we *claim* partial correctness.
- **Cosmetic residue (FINDING F4).** `render` over latex composite-negative
  coefficients yields a double space; LaTeX-invisible, untested, deliberately
  left (would otherwise diverge from the strip-rejoin idiom).
- **Constructed, not machine-checked.** The arithmetic here is finite-string
  identity, well within the bundled tier; no `[ESCALATION BOUNDARY]`.

---

## 8. Reproduce the machine check

```sh
kompile fvk/matprint.k --backend haskell        # compile the fragment semantics
kast    --backend haskell fvk/matprint-spec.k   # (optional) parse-check the claims
kprove  fvk/matprint-spec.k                      # expected: #Top  (all claims proved)
```

Until `kprove` returns `#Top`, results are **constructed, not machine-checked**;
the Findings (esp. **F1**, already fixed) stand independently of the machine check.

---

## 9. Test-redundancy note (recommendation only — conditioned on machine-check)

- Subsumed by (MATADD)/(MATMUL) once machine-checked (keep until then): the
  in-domain string-equality points — `test_matMul`'s coefficient rows,
  `test_MatMul_MatAdd`'s `2*(X+Y)`, the str/latex `test_MatrixElement_printing`
  (post-patch), and the `test_matAdd` rows (which also depend on PO-ORDER, so
  keep them as ordering pins regardless).
- **Keep always:** the **`str(I*A)` regression** (out-of-fragment totality pin,
  F1), the **pretty `test_MatrixElement_printing`** (validates the T5 model), and
  any termination/integration tests. None of these are subsumed.
- **Never auto-delete.** This is advice; CI savings are marginal (microsecond
  string asserts) and not the point — the point was F1.
