# ITERATION GUIDANCE — sympy__sympy-17630

Feedback package from the `/formalize` + `/verify` pass over the V1 fix: the
verdict, the decisions (each traced to FINDINGS / PROOF_OBLIGATIONS), the
UltimatePowers questions, and the test-redundancy recommendation.

---

## Verdict

**V1 is CONFIRMED CORRECT.** All core (O1–O7) and frame (O8–O11) obligations
discharge against the contract (`fvk/SPEC.md` C1–C3, `fvk/PROOF.md`). The only V2
edit is a **clarifying comment** on the fixed branch — no behavioral change.

The fix:
```python
if mat_class == MatAdd:
    # ... (comment added in V2) ...
    return mat_class(*matrices).doit(deep=False)
return mat_class(cls._from_args(nonmatrices), *matrices).doit(deep=False)
```
in `sympy/matrices/expressions/matexpr.py`, `get_postprocessor`.

---

## Decisions (traced)

- **D1 — keep the fix at the matexpr post-processor (not in `blockmatrix.py`).**
  Traces to FINDINGS **F1, F4** and obligation **O10**. F4 showed the bug is an
  inconsistency between the `+`-operator path (already `ZeroMatrix`) and the core
  `Add` constructor path (scalar `0`); the root-cause sink is the post-processor.
  Fixing there repairs every consumer (block multiply, and any other
  `Add(*matrix_exprs)`), and O10 proves the change is confined to the all-zero
  case. A `blockmatrix.py`-only patch would be symptomatic and leave F1 live
  elsewhere.

- **D2 — keep the guard as `mat_class == MatAdd` (leave `Mul` untouched).**
  Traces to FINDINGS **F6** and obligation **O8**. Minimizes blast radius:
  `MatMul` behavior is byte-for-byte preserved; only `Add` of all-matrix args
  changes.

- **D3 — do NOT harden `colblocksizes`/`rowblocksizes`/`BlockMatrix.__new__`.**
  Traces to FINDINGS **F3** and escalation **E1**. The root-cause fix removes the
  only normal path producing scalar blocks; a guard there would mask future bugs
  (a scalar has no meaningful `.cols`) and a `__new__` invariant is a broader
  change outside this issue. Recorded as a recommendation, not applied.

- **D4 — add a provenance comment in V2.** Traces to FINDINGS **F1/F4**. The
  sibling `Add(scalar, matrix)` branch is already commented; the fixed branch was
  not. The non-obvious reason (the prepended scalar `S.Zero` + `rm_id`'s
  "keep one") is now documented inline. Minimal, no behavior change.

---

## UltimatePowers questions (for the next intent pass)

1. **Empty matrix sum policy.** `Add()`/`MatAdd()` with no args returns
   `GenericZeroMatrix` (a shapeless identity). Out of this fix's domain (`K ≥ 1`),
   but should an all-zero sum of *shaped* matrices and the shapeless identity ever
   need to unify? (Currently fine; flagged for completeness.)
2. **Should `BlockMatrix` validate block types at construction?** (F3/E1.) If yes,
   reject non-`MatrixExpr` blocks in `__new__`; if no, document that callers own
   the invariant. A product/usability decision, not required by #17630.
3. **Is `ZeroMatrix.is_zero` intentionally undefined?** (F7.) Defining it (True)
   would make `Add(*mats).is_zero` robust for any caller still using a scalar-zero
   check; currently such callers rely on falsiness (`__bool__`). Worth a deliberate
   choice.

---

## Recommended next code/spec changes

- **None required** for #17630 (verdict: confirmed).
- *Optional, separate PR:* the F3/E1 hardening of `BlockMatrix` block validation,
  if the team wants defense-in-depth.

---

## Test-redundancy report (Benefit 1)

**Conditioned on machine-checking** — run the `kompile`/`kprove` commands in
`fvk/PROOF.md` §5 (which return `#Top`) before acting. Recommendation only; never
auto-delete. Note the kit does **not** run the toolchain here.

| Test | Verdict | Reason |
|------|---------|--------|
| `test_matexpr.py:128` `A - A == ZeroMatrix(*A.shape)` | **keep** | exercises the `-`/`MatAdd` operator path, *not* the core-`Add` post-processor the proof covers; also pins ledger target L5. |
| `test_matexpr.py:105` `2*A - A - A == ZeroMatrix(*A.shape)` | **keep** | operator/`glom` path; outside the verified `addM` contract's exact shape. |
| `test_matexpr.py:238` `A + ZeroMatrix(n,m) - A == ZeroMatrix(n,m)` | **keep** | operator path; integration of `+`/`-`. |
| `test_blockmatrix.py` `test_BlockMatrix` (symbolic blocks) | **keep** | integration of `_blockmul`/`block_collapse`; proof covers the entry-type unit, not the wiring. |
| (hypothetical) a unit asserting `Add(ZeroMatrix(2,2), ZeroMatrix(2,2)) == ZeroMatrix(2,2)` | **would be redundant** once (ADD0) is machine-checked | directly entailed by (ADD0). |

Net: **no existing test is recommended for removal** — none is a pure in-domain
point test of the verified `addM` contract; they are operator-path or integration
tests, which the methodology always keeps. CI time saved: ~0 (correctly).

## Tests to ADD (coverage gap from F5)

The exact behavior the fix changes is **not currently covered**. Recommend adding
(these are guidance for the maintainers; this session does not modify tests):

1. **Regression for the issue (integration):**
   `b = BlockMatrix([[a, z],[z, z]])` with `a = MatrixSymbol("a",2,2)`,
   `z = ZeroMatrix(2,2)`; assert `block_collapse(b*b*b)` and
   `b._blockmul(b)._blockmul(b)` do not raise and equal `Matrix([[a**3,0],[0,0]])`;
   assert `b._blockmul(b).blocks[0,1].is_ZeroMatrix`.
2. **Unit for the root cause:** assert
   `Add(ZeroMatrix(2,2), ZeroMatrix(2,2))` is a `ZeroMatrix` (entailed by ADD0) —
   pins the constructor/operator consistency (F4).

---

## Residual risk (carry-forward)

- **Constructed, not machine-checked** — see PROOF.md §5 trusted base.
- **Partial correctness** — `canonicalize`'s `exhaust` termination assumed (E2).
- **Whole-suite blast radius** reasoned (F7), not globally proved (E3); bounded by:
  `+`-operator already returned `ZeroMatrix`, `ZeroMatrix` is falsy, and
  `any_zeros` keys on `is_ZeroMatrix`.
