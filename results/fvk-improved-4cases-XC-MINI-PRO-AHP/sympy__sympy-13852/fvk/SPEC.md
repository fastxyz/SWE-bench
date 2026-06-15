# SPEC — polylog._eval_expand_func (sympy__sympy-13852)

Human-readable specification of the function under audit, plus the public intent
ledger. The formal version is `polylog-expand-spec.k` over `mini-sympy.k`; the
intent-only view is `INTENT_SPEC.md`; the adequacy check is `SPEC_AUDIT.md`.

## What the function is for

`polylog._eval_expand_func(self)` implements `expand_func(polylog(s, z))`: it turns a
polylogarithm into elementary/closed-form pieces **when one exists**, and otherwise
returns the polylog unchanged. It is reached by `expand(func=True)` /
`expand_func(...)`, which `sympy/core/function.py:expand_func` dispatches to each
`Function` node.

## Specified behavior (precondition → result)

The method is total; it dispatches on `(s, z) = self.args`:

| Case (precondition) | Result (postcondition) | Provenance |
|---|---|---|
| `s == 1` | `-log(1 - z)` (no `exp_polar`) | issue I2/I4 |
| `s == 2` and `z == 1/2` | `-log(2)**2/2 + pi**2/12` | issue I1 |
| `s` integer, `s <= 0` | rational function from the `u·d/du` loop (e.g. `s=0 → z/(1-z)`) | public test I5 |
| otherwise (symbolic `s`; `s ≥ 3`; `s == 2, z ≠ 1/2`) | `polylog(s, z)` unchanged | public test I5 |

**Key correctness property (I3):** the expansion must not change the derivative —
`d/dz(-log(1-z)) = 1/(1-z)` must equal `d/dz polylog(1,z) = polylog(0,z)/z = 1/(1-z)`.
This is the property the *old* `-log(1 + exp_polar(-I*pi)·z)` output violated.

## Public intent ledger

| # | Source | Quoted evidence | Semantic obligation | Status |
|---|---|---|---|---|
| L1 | prompt | "The answer should be -log(2)\*\*2/2 + pi\*\*2/12" + "polylog(2, Rational(1,2)).expand(func=True)" | `expand_func(polylog(2,1/2)) = -log(2)²/2 + π²/12` | encoded (PL2) |
| L2 | prompt | "polylog(1, z) and -log(1-z) are exactly the same function for all purposes" | `expand_func(polylog(1,z)) = -log(1-z)` | encoded (PL1) |
| L3 | prompt | "I don't see a reason for exp_polar here" / "having exp_polar … is just not meaningful" | result must not contain `exp_polar(-I*pi)` | encoded (PL1) |
| L4 | prompt | "expand_func changes the derivative of the function" (called a bug) | expansion preserves `d/dz`; `…diff…` reduces to 0 | encoded (PLDERIV-FIX) |
| L5 | prompt | "they have the same derivative, which is z/(1-z)" | `polylog(0,z)=z/(1-z)`, so `d/dz polylog(1,z)=1/(1-z)` | encoded (PLDERIV-FIX right) |
| L6 | docs | docstring `>>> expand_func(polylog(0, z))  z/(-z + 1)` | `s<=0` branch preserved | encoded (PL0) |
| L7 | public-test | `myexpand(polylog(-5, z), None)`, `polylog(s,1)=zeta(s)`, … | other reductions preserved | frame I5 |
| L8 | implementation | branch `if s == 2 and z == S.Half` | models the special-case dispatch (not intent by itself) | used for state shape only |
| S1 | prompt (SUSPECT) | `In[1]: polylog(2, 1/2)  Out[1]: polylog(2, 1/2)` | "stays unevaluated by default" | **NOT an obligation** — symptom display (see SPEC_AUDIT D1) |
| S2 | public-test (SUSPECT) | `myexpand(polylog(1, z), -log(1 + exp_polar(-I*pi)*z))` | old `exp_polar` output | **SUSPECT** — encodes the bug; must be updated, not preserved |

## Default-domain assumptions (named)

- **Principal branch** for `log`/`polylog`; the I2 identity holds on the branch cut
  (`z` real `> 1` ⇒ both sides have `Im = -pi`), confirmed numerically in the issue.
- **`expand_func` is opt-in**: non-universal closed forms live in
  `_eval_expand_func`, not automatic `eval` (which handles only universal
  `z ∈ {0,1,-1}`). This convention, plus the public-test pattern, settles design
  decision D1 toward the candidate placement — see `SPEC_AUDIT.md`.

## Trusted base / residual risk

- The `mini-sympy.k` fragment is an abstraction of SymPy's expression algebra and of
  the `s<=0` loop (modelled as `ratPolylog`, with `s=0` pinned). Faithfulness of that
  fragment is part of the trusted base.
- Proof is **partial-correctness, constructed, not machine-checked** (the MVP does
  not run `kprove`). Run the commands in `polylog-expand-spec.k` to upgrade it.
