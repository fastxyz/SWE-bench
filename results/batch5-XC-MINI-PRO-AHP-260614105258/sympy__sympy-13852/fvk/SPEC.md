# SPEC — `polylog._eval_expand_func` (sympy__sympy-13852)

**Target file:** `repo/sympy/functions/special/zeta_functions.py`
**Target function:** `polylog._eval_expand_func(self, **hints)`
**Mode:** intent-spec (align NL issue ↔ docstring ↔ tests ↔ code ↔ formal claim).
**Status label:** *constructed, not machine-checked* (no K toolchain is run here; the
`.k` fragments below are written and reasoned about, per the FVK MVP honesty gate).

This function is a pure, side-effect-free **dispatch** that rewrites a symbolic
`polylog(s, z)` node into a more elementary closed form when one is known, and
otherwise returns the node unchanged. There is no I/O, heap, or mutation of `self`.

---

## 1. Public intent ledger

| # | Source | Evidence (quoted / paraphrased) | Semantic obligation | Status |
|---|--------|----------------------------------|---------------------|--------|
| L1 | `prompt`/issue (PROBLEM.md:5-15) | "`polylog(2, Rational(1,2)).expand(func=True)` … The answer should be `-log(2)**2/2 + pi**2/12`" | `expand_func(polylog(2, 1/2)) = pi**2/12 - log(2)**2/2` | **must hold** (V1 target) |
| L2 | `prompt`/issue (PROBLEM.md:13-14) | `nsimplify(...)` cross-check prints `-log(2)**2/2 + pi**2/12` | the L1 value is the canonical printed form | supporting |
| L3 | `prompt`/issue (PROBLEM.md:20-26) | "Why does the expansion of `polylog(1, z)` have `exp_polar(-I*pi)`? … `polylog(1, z)` and `-log(1-z)` are exactly the same function for all purposes … both return the same values [over thousands of points]" | `expand_func(polylog(1, z)) = -log(1 - z)` (no `exp_polar`) | **must hold** (V1 target) |
| L4 | `prompt`/issue (PROBLEM.md:28-36) | `expand_func(diff(polylog(1,z) + log(1-z), z))` should be `0`; current code "changes the derivative" | `expand_func` must commute with `d/dz` (it must return an expression *equal* to `polylog(s,z)`) | **must hold** (frame/consistency) |
| L5 | `prompt`/issue (PROBLEM.md:38) | "exp_polar … winding number about 1 … irrelevant because log is not branched at 1" | the removed `exp_polar(-I*pi)` factor carried no analytic content | rationale for L3 |
| L6 | `name`/docstring (zeta_functions.py:249-258) | "If `s` is a negative integer, `0` or `1`, the polylogarithm can be expressed using elementary functions" via `expand_func()` | the `s∈{...,-1,0,1}` branches stay elementary (pre-existing); the `s=2,z=1/2` add is a *new* special value | frame (no regression) |
| L7 | `public-test` (test_zeta_functions.py:125-134) | `myexpand(polylog(0,z), z/(1-z))`, `myexpand(polylog(-1,z), z**2/(1-z)**2 + z/(1-z))`, `myexpand(polylog(-5,z), None)` | the `s ≤ 0` rational-function branch is **unchanged** and still correct | frame (no regression) |
| L8 | `public-test` (test_zeta_functions.py:137-159) | `lerchphi` expansion calls `polylog(s, ...)._eval_expand_func()` with **symbolic** `s` | for symbolic `s` the result is `polylog(s,z)` (the new branches must not fire) | frame (no regression) |
| L9 | `implementation` (V1 diff) | local import trimmed to `from sympy import log, expand_mul, Dummy` | `exp_polar`, `I` are now unused; `pi` resolves to the module-level import (line 4) | well-formedness |
| L10 | `docs`/standard | `polylog(s, 1) -> zeta(s)`, `polylog(s, -1) -> -dirichlet_eta(s)`, `polylog(s, 0) -> 0` handled in `eval` *before* expand | `eval` short-circuits `z∈{0,1,-1}`, so `_eval_expand_func` only ever sees `z∉{0,1,-1}` for those | domain restriction |

> No external requirements doc exists; intent is taken from the public issue,
> the in-repo docstring, the public tests, and the V1 baseline report. This is
> recorded explicitly per the FVK intent-evidence discipline.

---

## 2. Domain, inputs, and the partial function being specified

`self = polylog(s, z)`; the method reads `s, z = self.args`. By L10, `eval` has
already removed `z ∈ {0, 1, -1}` (those never reach this method via the public API).
`s` is any SymPy object; `z` is any SymPy object. The contract is a **case-defined
postcondition** on the returned expression `E := _eval_expand_func()`:

```
E(s, z) ==  -log(1 - z)                 if s == 1
        ==  pi**2/12 - log(2)**2/2       if s == 2  and  z == S.Half
        ==  (u d/du)^(-s)[u/(1-u)] |_{u=z}   if s is a concrete Integer and s <= 0
        ==  polylog(s, z)                otherwise   (incl. symbolic s, non-1/2 z)
```

**Universal correctness invariant (the real postcondition, L3/L4):**
For every `(s, z)` in the domain, `E(s, z)` is *analytically equal* to
`polylog(s, z)` — equal as SymPy expressions under `.n()` at every point where
`polylog` is defined, **with consistent branch cuts**. The closed forms are merely
more elementary representatives of the same function. This is the property that
makes `expand_func` commute with `diff` (L4).

---

## 3. mini-X K semantics — `polylog-expand.k` (the dispatch fragment)

The only language constructs this method uses are: tuple-unpack, a chain of
`if <guard>: return <expr>`, the boolean/equality guards `s == 1`,
`s == 2 and z == S.Half`, `s.is_Integer and s <= 0`, and (in the unchanged
`s ≤ 0` branch) a counting `for` loop that applies the Euler operator `u·d/du`.
We model the *control-flow decision* faithfully; the returned CAS expressions are
opaque `Expr` tokens whose analytic meaning is supplied by the VC theory (§5,
PROOF.md). This is the honest mini-X scope: K decides *which* branch fires; the
analytic identities are escalated.

```k
// polylog-expand.k  —  mini fragment semantics (constructed, not machine-checked)
module POLYLOG-EXPAND-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  // s is either a concrete integer literal or the marker `symS` (a free symbol).
  syntax SVal ::= Int | "symS"
  // z is either the exact rational 1/2 (`half`), or `zsym`/other (`zoth`).
  syntax ZVal ::= "half" | "zoth"

  // Opaque result expressions (only the constructors the four branches return).
  syntax Expr ::= "neglog1mz"             // -log(1 - z)
                | "dilogHalf"             // pi**2/12 - log(2)**2/2
                | "eulerLi" "(" Int ")"   // (u d/du)^(-n)[u/(1-u)]|_{u=z},  n <= 0
                | "polylogNode"           // polylog(s, z)  (no-op)

  syntax KItem ::= "expand" "(" SVal "," ZVal ")"
  syntax KResult ::= Expr
endmodule

module POLYLOG-EXPAND
  imports POLYLOG-EXPAND-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:KItem </k> <out> .K </out>

  // Branch 1 :  if s == 1: return -log(1 - z)           (any z; eval removed z=±1,0)
  rule <k> expand(1, _Z) => . ... </k> <out> _ => neglog1mz </out>

  // Branch 2 :  if s == 2 and z == 1/2: return Li_2(1/2) closed form
  rule <k> expand(2, half) => . ... </k> <out> _ => dilogHalf </out>

  // Branch 3 :  if s.is_Integer and s <= 0: return the Euler-operator rational fn
  //   (concrete integer S, S <= 0; S = 2 already consumed by Branch 2 only at z=half)
  rule <k> expand(S:Int, _Z) => . ... </k> <out> _ => eulerLi(S) </out>
    requires S <=Int 0

  // Branch 4 (frame) : everything else — symbolic s, or s==2 with z != 1/2, etc.
  rule <k> expand(symS, _Z) => . ... </k> <out> _ => polylogNode </out>
  rule <k> expand(2, zoth) => . ... </k> <out> _ => polylogNode </out>
  rule <k> expand(S:Int, _Z) => . ... </k> <out> _ => polylogNode </out>
    requires S >=Int 3
endmodule
```

The four rules are **mutually exclusive and exhaustive** over `SVal × ZVal`
(Finding F3): `s==1` (B1) ⊔ `s==2 ∧ z=half` (B2) ⊔ `s∈ℤ, s≤0` (B3) ⊔
[`symS`, or `s==2 ∧ z≠half`, or `s≥3`] (B4). This mirrors the Python `if`/`if`/`if`
fallthrough exactly because the Python guards are pairwise disjoint on the values
that reach each line (no `elif` needed: `s==1`, `s==2∧z=½`, and `s≤0` cannot hold
simultaneously).

> Note: the Euler-operator **loop** inside Branch 3 (`for _ in range(-s): start =
> u*start.diff(u)`) is a genuine counting loop. It is **unchanged by V1**; its own
> circularity is stated in §4.3 for completeness, but it is out of the audited
> change's scope and is already pinned by tests L7.

---

## 4. Reachability claims — `polylog-expand-spec.k`

```k
requires "polylog-expand.k"
module POLYLOG-EXPAND-SPEC
  imports POLYLOG-EXPAND

  // ----- (EXPAND-S1)  L3, L5 ---------------------------------------------------
  // SPEC-PROVENANCE:
  // - from_prompt: "polylog(1, z) and -log(1-z) are exactly the same function"
  //   => post: result == -log(1 - z), and -log(1-z) ≡ polylog(1,z) analytically.
  // - from_prompt(L5): exp_polar(-I*pi) factor is meaningless (winding about 1).
  // - from_code: the s==1 branch returns -log(1 - z).
  claim <k> expand(1, Z:ZVal) => . </k> <out> _ => neglog1mz </out>   [all-path]

  // ----- (EXPAND-HALF)  L1, L2 -------------------------------------------------
  // SPEC-PROVENANCE:
  // - from_prompt: "The answer should be -log(2)**2/2 + pi**2/12"
  // - from_docs: standard dilogarithm value Li_2(1/2) = pi^2/12 - (ln 2)^2/2.
  claim <k> expand(2, half) => . </k> <out> _ => dilogHalf </out>    [all-path]

  // ----- (EXPAND-FRAME-SYM)  L8 ------------------------------------------------
  // symbolic s must leave the node untouched (lerchphi caller depends on this).
  claim <k> expand(symS, Z:ZVal) => . </k> <out> _ => polylogNode </out> [all-path]

  // ----- (EXPAND-FRAME-2)  L7/L8 -----------------------------------------------
  // s == 2 with z != 1/2 must NOT collapse to the special value.
  claim <k> expand(2, zoth) => . </k> <out> _ => polylogNode </out>  [all-path]

  // ----- (EXPAND-NEG)  L6, L7  (pre-existing branch; stated for completeness) --
  claim <k> expand(S:Int, Z:ZVal) => . </k> <out> _ => eulerLi(S) </out>
    requires S <=Int 0  [all-path]
endmodule
```

### 4.3 Loop circularity for the unchanged `s ≤ 0` branch (completeness only)

The Euler-operator loop computes `Li_S(z)` for integer `S ≤ 0`. Generalized over
the iteration counter `K` and the running expression `start`:

```
(EULER-LOOP)  running `for _ in range(-S): start = u*start.diff(u)`
   from counter K with start = (u d/du)^K [u/(1-u)]
   reaches counter -S with start = (u d/du)^(-S) [u/(1-u)]
   requires  0 <=Int K  andBool  K <=Int -S        // soundness side condition
```

Closed form / invariant: after `j` iterations `start = (u d/du)^j[u/(1-u)] =
Li_{-j}(u)` (standard generating-function identity). This branch is **unchanged by
V1** and already covered by tests L7; we do not re-prove it in depth.

---

## 5. Side conditions and the verification-condition theory

The branch dispatch (§4) is pure boolean/integer logic — Z3-tier. The **analytic
content** lives in two non-arithmetic VCs that connect an opaque `Expr` token to
`polylog`:

- **VC-Li1** : `neglog1mz ≡ polylog(1, z)` as SymPy functions, including branch
  cuts (for real `z>1`, both have imaginary part `-pi`). *(escalation tier —
  special-function identity, see PROOF.md; discharged by the standard
  `Li_1(z) = -log(1-z)` identity + the issue's thousands-of-points numerical
  agreement + SymPy `hyperexpand` parity at test_hyperexpand.py:582.)*
- **VC-Li2½** : `dilogHalf ≡ polylog(2, 1/2)`, i.e. `pi**2/12 - log(2)**2/2 =
  Li_2(1/2)`. *(escalation tier — closed-form dilogarithm identity; numerical
  witness `0.5822405264…`.)*

A third, structural VC ties the postcondition to L4:

- **VC-Frame** : because each branch's result is analytically equal to
  `polylog(s, z)` (VC-Li1, VC-Li2½, the Euler identity, or identity for the no-op),
  and `polylog`'s `fdiff` is unchanged, `d/dz E = E(s-1)/z` holds wherever
  `polylog`'s does ⇒ `expand_func` commutes with `diff` (closes L4).

---

## 6. Plain-English spec note (for a developer who never opens the `.k`)

`polylog(s, z).expand(func=True)` returns a *different but equal* way of writing the
same polylogarithm whenever a simpler one is known:

- **`s = 1`** → `-log(1 - z)`. This is the same function as `polylog(1, z)`
  everywhere, including the branch cut on `[1, ∞)`; there is deliberately **no**
  `exp_polar` factor (it would encode a winding number about `z = 1`, where `log`
  is not branched, i.e. nothing).
- **`s = 2`, `z = 1/2`** → `pi**2/12 - log(2)**2/2`, the classical value of the
  dilogarithm `Li_2(1/2) ≈ 0.582240526`.
- **`s` a concrete integer `≤ 0`** → a rational function (unchanged from before).
- **anything else** (symbolic `s`, or `s = 2` with `z ≠ 1/2`, or `s ≥ 3`) →
  `polylog(s, z)` unchanged.

Because every returned form equals the original function, `expand_func` is safe to
apply under a derivative: `expand_func(diff(polylog(1, z) + log(1 - z), z)) == 0`,
which was *not* true before V1.
