# PROOF_OBLIGATIONS.md — sympy-14248

Each obligation: statement, why it is required (intent trace), and V1/V2 status.
Discharge details are in [`PROOF.md`](PROOF.md). Findings referenced from
[`FINDINGS.md`](FINDINGS.md).

Legend: ✅ holds (V1 & V2) · ⚠️ holds only in V2 (V1 violated) · ◻️ out-of-domain /
not claimed.

---

## Core bug-fix obligations (from the prompt "print like a-b")

| ID | Obligation | Trace | V1 | V2 |
|----|-----------|-------|----|----|
| **PO-ADD-SEP** | In `_print_MatAdd`, for every term `i`, the separator emitted before `bodyOf(s_i)` is `"-"` iff `s_i.startswith('-')`, else `"+"`. | prompt: differences print like `a-b`; code: per-term `sign`. | ✅ | ✅ |
| **PO-ADD-NOPLUSNEG** | The output never contains the substring `"+ -"` introduced by a term (the exact V0 bug `+ (-1)*` / `+ -1 ` / `+ -`). | prompt: the three buggy outputs. | ✅ | ✅ |
| **PO-ADD-FAITHFUL** | Output `= render(SS)`: the rendered sum has each term with its correct sign and body; equals the mathematical MatAdd. | prompt; scalar-printer convention. | ✅ | ✅ |
| **PO-ADD-LEAD** | A leading `+` is suppressed; a leading `-` is kept. | code: `if sign=='+': sign=''`. | ✅ | ✅ |
| **PO-MM-SIGN** | str `_print_MatMul`: output begins with `-` **iff** the coefficient is a negative number; BODY (the `*`-join) never begins with `-`. (This is the precondition PO-ADD-SEP relies on for MatMul terms.) | prompt: no `(-1)*b`; code: `sign`+fold. | ✅ | ✅ |
| **PO-MM4-NEG1** | latex `_print_MatMul`: a `-1` coefficient prints as a bare leading `-` (drops the `1`); every other coefficient is byte-for-byte unchanged from pre-fix. | test_matMul (`-2 A`,`- \sqrt 2 A`,…); prompt. | ✅ | ✅ |
| **PO-PRETTY-SEP** | pretty `_print_MatAdd`: a non-leading term gets a bare `' '` separator iff `S(item.args[0]).is_negative`, else `' + '`; the term supplies its own `-`. | prompt (pretty case); test_MatrixElement. | ✅ | ✅ |

## Totality / well-definedness obligations

| ID | Obligation | Trace | V1 | V2 |
|----|-----------|-------|----|----|
| **PO-MM-TOTAL** | str `_print_MatMul` returns (does not raise) for **every** MatMul, including a non-real numeric coefficient (`I`). | impl fact: `as_coeff_mmul` coeff may be non-real; **FINDING F1**. | ⚠️ **VIOLATED** (`I < 0` raises) | ✅ (`c.is_negative` total) |
| **PO-MM4-TOTAL** | latex `_print_MatMul` returns for every MatMul (`== -1` never raises). | code: equality test. | ✅ | ✅ |
| **PO-PRETTY-TOTAL** | pretty `_print_MatAdd` does not raise for in-domain terms; `S(item.args[0])` is defined for MatMul / MatrixSymbol / explicit-matrix terms. | FINDING F3. | ✅ (in-domain) | ✅ |
| **PO-ADD-TOTAL** | str/latex `_print_MatAdd` return for every **non-empty** MatAdd (`n ≥ 1`). Empty MatAdd is **out of domain** (FINDING F2). | impl: `validate` blocks empty; parity with `_print_Add`. | ✅ for `n≥1`; ◻️ `n=0` | same |

## Regression-safety obligations (preserve existing public behaviour)

| ID | Obligation | Trace | V1 | V2 |
|----|-----------|-------|----|----|
| **PO-REG-2XY** | `str(2*(X+Y)) == "2*(X + Y)"`. | test_str::test_MatMul_MatAdd. | ✅ | ✅ |
| **PO-REG-MM** | latex `_print_MatMul` keeps `2 A`, `2 x A`, `-2 A`, `1.5 A`, `\sqrt{2} A`, `- \sqrt{2} A`, `2 \sqrt{2} x A`, `-2 A (…)`. | test_latex::test_matMul. | ✅ | ✅ |
| **PO-REG-ADD** | latex `_print_MatAdd` renders the four `test_matAdd` cases for the canonical MatMul-first ordering. | test_latex::test_matAdd. | ✅ | ✅ |
| **PO-REG-EL** | pretty `(A-B)[0,0]` prints `(-B + A)[0, 0]` (unchanged, already clean). | test_pretty::test_MatrixElement_printing. | ✅ | ✅ |
| **PO-REG-DOCTEST** | doctests unchanged: `I + 2*A*B`, `A + B + C`, `A*B*C`. | matexpr/matadd/matmul docstrings. | ✅ | ✅ |

## Ordering assumption (discharged by observation, not proved)

| ID | Obligation | Trace | Status |
|----|-----------|-------|--------|
| **PO-ORDER** | `MatAdd` canonical order places `MatMul` terms before bare `MatrixSymbol`s, so in `test_matAdd` the negative term is first and strip-rejoin yields the listed string. | issue output `(-1)*B + (-1)*A*B + A` (A last); blockmatrix etc. | ✅ observed (sort by `default_sort_key`); not part of the printer contract — the printer is correct for *any* ordering, only the *exact test string* depends on the order. |

---

## The one obligation that drove a code change

**PO-MM-TOTAL** is the sole obligation V1 fails. Everything else holds in both V1
and V2. The V2 edit (`c < 0` → `c.is_negative`) discharges PO-MM-TOTAL while
provably preserving PO-MM-SIGN and all PO-REG-* (identical output on every real
coefficient — see PROOF §4). No other source edit is warranted by the
obligations; F2/F3/F4/F5/F6 are explicitly *kept* with justification.
