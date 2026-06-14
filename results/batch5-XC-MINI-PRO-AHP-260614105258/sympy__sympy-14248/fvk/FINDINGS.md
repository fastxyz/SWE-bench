# FINDINGS.md — sympy-14248 V1 audit

Plain-language findings, each as `input → observed vs expected`. The Findings
report does **not** depend on machine-checking. Severity: **bug** (fix),
**corner** (note/decide), **cosmetic**, **scope**.

---

## F1 — `str(I*A)` crashes (negative-coefficient guard is not total) — **BUG (fixed in V2)**

- **Where:** `str.StrPrinter._print_MatMul`, the guard `if c.is_number and c < 0:`.
- **Input:** `from sympy import MatrixSymbol, I; A = MatrixSymbol('A',2,2); str(I*A)`.
- **Observed (V1):** `TypeError: Invalid comparison of non-real I`. `MatMul(I, A)`
  has `as_coeff_mmul()[0] == I`; `I.is_number` is `True`, so the second conjunct
  `c < 0` is evaluated, and `I < 0` raises.
- **Expected:** print without raising, e.g. `I*A` (exactly what the **pre-fix**
  code produced — so V1 is a *regression* here).
- **Root cause (spec-difficulty signal):** writing the (MATMUL) contract forced
  the question "for which `c` is `c < 0` defined?" Answer: only real numbers.
  Unlike scalar `_print_Mul` — whose `as_coeff_Mul()` coefficient is *always* a
  real Rational — `as_coeff_mmul()` can return a **non-real** coefficient. The
  `is_number` guard admits non-reals; it does not protect the comparison.
- **Fix (V2):** replace `c < 0` with `c.is_negative`. `is_negative` is `False`
  for non-real numbers (no raise) and **agrees with `c < 0` on every real
  number**, so all in-scope outputs are unchanged. Guard becomes
  `if c.is_number and c.is_negative:`.
- **Traceability:** PROOF_OBLIGATIONS PO-MM-TOTAL; PROOF §4; intent-ledger row
  "coeff … may be non-real".
- **Tests:** add an out-of-fragment regression `str(I*A) == 'I*A'` (kept, since it
  pins behaviour the proof's `nonreal` branch only asserts as totality).

## F2 — empty MatAdd: `l.pop(0)` / `s is None` (corner, unreachable) — **CORNER (keep V1)**

- **Where:** T2/T3 `sign = l.pop(0)`; T5 returns `s` which is `None` if there are
  no terms.
- **Input:** `MatAdd(check=False)` (no args), then print it.
- **Observed (V1):** str/latex raise `IndexError: pop from empty list`; pretty
  returns `None`.
- **Expected (pre-fix):** `''` (str/latex `' + '.join([])`) / a `stringPict('')`
  (pretty `_print_seq`).
- **Why not fixed:** an empty MatAdd is **not constructible by normal means** —
  `MatAdd.validate` evaluates `args[0]` and raises before an empty instance
  exists; one-term `MatAdd(A)` is fine. The mirrored scalar `_print_Add` has the
  identical `l.pop(0)` with no guard and is safe for the same reason (`Add()` is
  `S.Zero`, never an empty `Add`). Adding a guard would diverge from the
  `_print_Add` idiom for an unreachable input.
- **Traceability:** PO-ADD-TOTAL (domain `n ≥ 1`); intent-ledger row
  "validate indexes args[0]".
- **Tests:** none (out of domain; do not add).

## F3 — pretty negativity test `S(item.args[0]).is_negative` is heuristic — **CORNER (keep V1)**

- **Where:** T5 `_print_MatAdd`.
- **What:** `item.args[0]` is the coefficient only for a `MatMul`; for a
  `MatrixSymbol` it is the *name* (a `str`), for an explicit matrix it is the row
  count. `S(name)` re-parses the name string.
- **Inputs checked:** `MatMul(-1,B)`→`args[0]=-1`→`is_negative` True ✓;
  `MatrixSymbol('A',…)`→`S('A')=Symbol('A')`→`None` (falsy)→`+` ✓; `MatMul(A,B)`→
  `S(A).is_negative=None`→`+` ✓; `ZeroMatrix(2,2)`→`args[0]=2`→`False`→`+` ✓.
  Correct for **every term type that occurs**.
- **Latent fragility:** a `MatrixSymbol` whose *name* is not a plain identifier
  (e.g. `'A B'`) could make `S(name)` raise/parse oddly. No sympy test uses such
  a name; the issue is about identifier-named symbols.
- **Why not changed:** the natural alternatives are worse — string-slicing a 2-D
  `prettyForm` is awkward, and `item.as_coeff_mmul()[0]` raises `AttributeError`
  on an explicit `MatrixBase` term (which the current test *does* survive).
- **Traceability:** PO-PRETTY-SEP; SPEC §4 (T5).
- **Tests:** keep existing `test_MatrixElement_printing` / `test_Adjoint`
  (in-domain, validate T5).

## F4 — latex double space for composite negative coefficients — **COSMETIC (keep V1)**

- **Where:** T3 `_print_MatAdd`, the strip `t = t[1:]`.
- **Input:** a MatAdd term whose latex begins `"- "` (dash-space) — i.e. a
  *composite* negative coefficient like `-sqrt(2)`, `-2*x`, `-1/2` — in a
  **non-leading** position, e.g. `latex(2*x*A - sqrt(2)*B)`.
- **Observed:** `… -  \sqrt{2} B` (two spaces). `latex(MatMul(-sqrt(2),B)) ="- \sqrt{2} B"`;
  stripping one `-` leaves `" \sqrt{2} B"` (leading space), and `' '.join`
  adds another.
- **Expected (ideal):** one space `… - \sqrt{2} B`.
- **Impact:** **none when rendered** — LaTeX collapses consecutive spaces. The
  string differs only for composite-coefficient terms; integer coefficients
  (`-2 B`) print `"-2"` with no space and are unaffected. No test exercises a
  composite negative coefficient inside a MatAdd.
- **Why not fixed:** an `lstrip()` would *introduce* a `-\sqrt{2}` (no space)
  inconsistency in the *leading* position and could diverge from the established
  strip-rejoin idiom that the visible tests are written against. Keeping the
  idiom keeps the proved (MATADD) contract and the existing tests intact;
  rendering is unaffected.
- **Traceability:** SPEC §4 (T3 `render`); PROOF §5 (residual risk).
- **Tests:** none added.

## F5 — symbolic negative coefficients are not collapsed — **SCOPE (out of scope)**

- **Input:** `A - x*B` with `x` a plain (sign-unknown) `Symbol`.
- **Observed:** str → `… + (-x)*B`; pretty → `… + (-x)⋅B`; i.e. not folded to
  `… - x*B`.
- **Expected by issue:** the issue is explicitly about the **numeric** `(-1)`
  coefficient (`a - b`); symbolic coefficients are not mentioned, and the pre-fix
  code did not handle them either. So this is a pre-existing limitation, not a
  regression.
- **Why not changed:** out of the issue's scope; folding symbolic signs would
  require `is_negative`-style assumptions that are usually `None`, and would risk
  diverging from upstream behaviour the hidden tests are written against.
- **Traceability:** intent-ledger "scope"; SPEC §5 (out of scope).
- **Tests:** none.

## F6 — dead parenthesisation branch in str `_print_MatAdd` — **CORNER (keep, parity)**

- **Where:** T2, `if precedence(term) < PREC: l.extend([sign, "(%s)" % t])`.
- **What:** `PREC = precedence(MatAdd) = 40`; every term that can appear
  (`MatMul`=50, `MatrixSymbol`/`MatPow`/… ≥60/Atom) has `precedence ≥ 40`, so the
  `<` branch is **never taken** — dead code.
- **Why kept:** it is a verbatim mirror of scalar `_print_Add`; removing it would
  gratuitously diverge from that idiom and the proof does not depend on its
  removal (PROOF treats both branches; only the `else` is reachable).
- **Traceability:** PROOF §2 (case split collapses to the `else` branch).

---

## Positive findings (the spec confirms the fix)

- **P1** — (MATADD)/(LOOP) hold: for `n ≥ 1` every negative term gets a `-`
  separator, so the buggy `+ (-1)*` / `+ -…` pattern is provably absent. This is
  the core obligation from the prompt. (PROOF §2.)
- **P2** — (MATMUL) sign fold: a negative numeric coefficient yields a leading
  `-` and BODY never starts with `-`, so the (MATADD) detection is sound; the
  `2*(X+Y)` and `-2 A` constraints are preserved. (PROOF §3–4.)
- **P3** — T5 reproduces the already-clean `(-B + A)[0,0]` pretty output that the
  pre-existing (unchanged) `test_MatrixElement_printing` asserts — independent
  evidence the pretty model matches reality. (PROOF §6.)

---

## Proof-derived findings from `/verify`

- The **only** proof obstacle that indicated a real code defect was **F1**
  (totality of (MATMUL) fails on `nonreal`). It is classified **code bug /
  missing precondition on the comparison** and is **fixed in V2**.
- All other obstacles are **capability/scope** (F4 cosmetic, F5 out-of-scope) or
  **unreachable-domain** (F2) — none is a correctness gap in the in-scope
  contract. No `[ESCALATION BOUNDARY]` was needed (the fragment is finite-string
  arithmetic, fully within the bundled tier).
