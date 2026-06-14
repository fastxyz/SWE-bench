# SPEC.md — formal specification of the V1 fix for sympy-14248

**Mode:** intent-spec (align NL intent ↔ code ↔ formal spec).
**Status:** constructed, **not** machine-checked (FVK MVP: no `kompile`/`kprove` run).
**Artifacts:** [`matprint.k`](matprint.k) (mini-X fragment semantics),
[`matprint-spec.k`](matprint-spec.k) (claims), this note.

---

## 1. Targets under verification

The V1 fix touches five printer methods. They split into two behaviours:

| # | Function | Role |
|---|----------|------|
| T1 | `str.StrPrinter._print_MatMul` | fold a negative numeric coefficient into a leading `-` |
| T2 | `str.StrPrinter._print_MatAdd` | join terms with per-term sign (loop) |
| T3 | `latex.LatexPrinter._print_MatAdd` | same loop, latex |
| T4 | `latex.LatexPrinter._print_MatMul` | drop the `1` of a `-1` coefficient → leading `-` |
| T5 | `pretty.PrettyPrinter._print_MatAdd` | same join, over 2-D `prettyForm`s |

T2 and T3 share one algorithm (the term loop); T1/T4 share the goal "make a
negative term's printed form begin with `-`" so the T2/T3 loop can detect it.
T5 reaches the same end through `prettyForm` mechanics.

---

## 2. Public intent ledger

| Source | Quoted / observed evidence | Semantic obligation | Status |
|---|---|---|---|
| prompt (`PROBLEM.md`) | "differences like a-b are represented as the sum of a with `(-1)*b`, but they are supposed to **print like a-b**" | A MatAdd term with a negative coefficient must be rendered with a `-` separator, **never** `+ (-1)*…` / `+ -1 …` / `+ -…`. | **core obligation** |
| prompt | the three buggy outputs `(-1)*B + (-1)*A*B + A`, `-B + -A⋅B + A`, `-1 B + -1 A B + A` | The defect spans str, pretty, latex; all three must be fixed. | core obligation |
| prompt | "I tried three printers: str, pretty, and latex" | Scope = exactly these three human-readable printers. (code-gen printers e.g. `pycode` out of scope.) | scope |
| name/idiom | scalar `_print_Add` / `_print_Mul` already render `a - b` | The matrix variants should match that established convention (strip leading `-`, fold negative coeff). | derived obligation |
| public-test (`test_latex.py::test_matMul`) | `-2 A`, `- \sqrt{2} A`, `2 A`, … | T4 must keep all non-`-1` coefficients verbatim; only the exact `-1` is special-cased. | constraint |
| public-test (`test_latex.py::test_matAdd`) | `C-2*B ∈ {'-2 B + C','C -2 B'}`, etc. | T3 must render these (for the canonical, MatMul-first ordering) correctly. | constraint |
| public-test (`test_pretty.py::test_MatrixElement_printing`) | `(-B + A)[0, 0]` (already clean pre-fix) | T5 must reproduce `-B + A` for `A - B`. | constraint (validates T5) |
| public-test (`test_str.py::test_MatMul_MatAdd`) | `2*(X + Y)` | T1 must leave a non-negative coefficient and the inner-MatAdd parens unchanged. | constraint |
| implementation | `MatMul.is_Mul == False`, `MatMul.is_Number == False` | `_coeff_isneg` returns False on every MatMul ⇒ negativity must be detected another way (printed-string `'-'` prefix, or `S(args[0]).is_negative`). | implementation fact |
| implementation | `MatMul.as_coeff_mmul()` coeff = `Mul(*scalars)` may be **non-real** (e.g. `I`) | `c < 0` is **not** total on that coefficient; `I < 0` raises. → **FINDING F1**. | proof-finding |
| implementation | `MatAdd.validate` indexes `args[0]` ⇒ an empty MatAdd is not normally constructible | the loop's `l.pop(0)` assumes `n ≥ 1`; empty is an unreachable corner. → **FINDING F2**. | proof-finding |

No external requirements doc exists beyond the issue; the spec is inferred from
the prompt, the public tests, the scalar-printer convention, and the code.

---

## 3. Mini-X semantics (the fragment that is actually used)

See [`matprint.k`](matprint.k). The only datum `_print_MatAdd` reads from a term
is its **printed string** and the single predicate `s.startswith('-')`; the only
datum it writes is the joined output string. So the fragment is a string/list
algebra:

- `String` with `+String` (concat), `substrString` (models `t[1:]`),
  `lengthString`/`substrString(_,0,1)` (models `t.startswith('-')`);
- a working `List` `l` with append and `pop(0)`;
- a `while`-style loop over the input term list `<terms>`.

A MatAdd term is modelled **by its printed string** `s_i` (everything the loop
needs). `_print_MatMul`'s sign decision is modelled by a 4-valued `Coeff`
(`neg`, `nonneg`, `nonreal`, `sym`) — the trichotomy the code branches on, plus
the `nonreal` case the audit surfaced.

This is the deliberate MVP "mini-X" stopgap; it is faithful to the control flow
and string operations of the real Python, not to sympy's whole object model.

---

## 4. Function contracts (reachability claims)

Full K in [`matprint-spec.k`](matprint-spec.k). In words:

### (MATADD) — T2/T3, `_print_MatAdd`
Define, for a non-empty term-string list `SS = [s_0,…,s_{n-1}]`:
- `sgOf(s) = "-" if s.startswith('-') else "+"`,
- `bodyOf(s) = s[1:] if s.startswith('-') else s`,
- `render(SS) = head(sgOf(s_0)) + bodyOf(s_0) + " " + sgOf(s_1) + " " + bodyOf(s_1) + …`
  where `head("+")=""`, `head("-")="-"`.

**Contract:** `requires n ≥ 1` ⇒ `printMatAdd(SS)` terminates and returns
`render(SS)`. The intended **well-formedness** property `wf` (no `"+ -"` ever
appears) is a corollary of `render`: a negative term contributes `… + " " + "-" +
" " + bodyOf …`, i.e. a `-` separator, not `+`.

### (LOOP) — circularity for the term loop
Generalised over the partial working list `LACC` and the remaining terms `TS`:
running `#loop` appends, for each remaining `s ∈ TS`, the two tokens
`sgOf(s), bodyOf(s)`. No numeric side condition is needed — the loop is
structural recursion over the finite `<terms>` list (contrast the `sum` example,
whose loop needs `I ≤ N+1`).

### (MATMUL) — T1, `str._print_MatMul` sign fold (+ totality)
`printMatMul(c, BODY)` returns `"-" + BODY` if `c` is a **negative number**, else
`BODY`, where `BODY` (the `*`-join of the sign-folded factors) never begins with
`-`. **Totality is part of the contract:** the function must return for *every*
coefficient, including `nonreal`. V2's guard `c.is_number and c.is_negative`
makes all four `Coeff` cases reduce; V1's guard `c < 0` has **no** reduction for
`nonreal` (the guard raises) — see FINDING F1 and PROOF §4.

### T4 `latex._print_MatMul`, T5 `pretty._print_MatAdd`
- T4: `args[0] == -1 ⇒ "-" + join(args[1:])`, else `join(args)`. The comparison
  `== -1` is total (never raises). Establishes the same "negative ⇒ leading `-`"
  precondition that (MATADD) relies on, for the `-1` case; other negatives already
  print with a leading `-` via `self._print`.
- T5: same separator logic as (MATADD) but the negativity test is
  `S(item.args[0]).is_negative` (a coefficient/string fact) because a 2-D
  `prettyForm` cannot be string-sliced. Sound for every term that actually occurs
  (MatMul coeff, MatrixSymbol name, explicit-matrix row count) — see FINDING F3.

---

## 5. What is proved vs assumed

- **Proved (constructed):** (MATADD), (LOOP), (MATMUL) over the mini-X fragment —
  the bug-fix property `wf` and totality. See [`PROOF.md`](PROOF.md).
- **Trusted base:** adequacy of the mini-X fragment vs. real CPython string/list
  semantics; that the modelled `Coeff` cases exhaust sympy coefficients; the
  reachability metatheory; and that `self._print` of any matrix factor never
  begins with `-` except via a negative coefficient (justified in PROOF §3).
- **Out of scope (findings, not proved):** symbolic negative coefficients
  (`-x·B`), the empty-MatAdd corner, latex double-space cosmetics — all in
  [`FINDINGS.md`](FINDINGS.md).
