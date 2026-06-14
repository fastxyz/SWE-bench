# SPEC.md — formal specification of the `nthroot_mod` fix (sympy__sympy-18199)

Target: `repo/sympy/ntheory/residue_ntheory.py`, function `nthroot_mod(a, n, p, all_roots=False)`,
specifically the branch added by the V1 fix at lines **779–781**:

```python
    if a % p == 0:
        # ``x**n = 0 (mod p)`` has the single root ``x = 0`` for prime ``p``
        return [0] if all_roots else 0
```

> **Scope.** `/formalize` is run in *intent-spec mode*. The verified object is the
> **new branch** and its interaction with the surrounding guards. The two pre-existing
> solving paths (`_nthroot_mod1`, and the gcd-on-exponents loop) are **assumed correct
> on their own domain** (`a % p != 0`) — they are separately tested and untouched by this
> change; their full correctness is an explicit `[ESCALATION BOUNDARY]` (see §5).

---

## 1. Public intent ledger

| # | Source | Evidence (quoted) | Semantic obligation | Status |
|---|--------|-------------------|---------------------|--------|
| L1 | prompt (`PROBLEM.md`) | "nthroot_mod function misses one root of x = 0 mod p." | When `0` is a root of `x**n ≡ a (mod p)`, it must appear in the result. | **must-hold** |
| L2 | prompt | "when a % p == 0. Then x = 0 mod p is also a root of this equation." | `a % p == 0 ⟹ 0` is a root. (And `0` is a root `⟺ a % p == 0`, for `n ≥ 1`.) | **must-hold** |
| L3 | prompt | "`nthroot_mod(17*17, 5 , 17)` has a root `0 mod 17`. But it does not return it." | Concrete case: `nthroot_mod(289,5,17)` must report `0`; `…,True` must contain `0`. | **must-hold (regression pin)** |
| L4 | docstring | "Find the solutions to `x**n = a mod p`" | Result = **the** solution set (complete), each in `[0, p)`. | must-hold |
| L5 | docstring | "all_roots : if False returns the smallest root, else the list of roots" | `all_roots=False` → smallest root (int); `True` → sorted list of all roots. | must-hold |
| L6 | code (line 776) | `if not isprime(p): raise NotImplementedError` | Domain is **prime `p`** only; composite `p` raises (must be **preserved**). | frame / preserve |
| L7 | code (lines 774–775) | `if not is_nthpow_residue(a, n, p): return None` | No root ⟹ `None`. Must not return `None` when a root exists. | must-hold |
| L8 | code (line 771) | `if n == 2: return sqrt_mod(a, p, all_roots)` | `n == 2` is delegated to `sqrt_mod` (which already handles `a≡0`). | frame / preserve |
| L9 | tests (`test_residue.py:182`) | `for a in range(1, p - 1): … nthroot_mod(a,q,p,True) …` | Exhaustive check **excludes** `a ≡ 0`; behavior there must stay correct (regression frame). | preserve |

No external requirements doc beyond the issue text; spec is inferred from the prompt
(L1–L3), the docstring (L4–L5), and the implementation guards (L6–L8). Marked accordingly.

---

## 2. Spec-only abstractions (verification vocabulary, not language constructs)

Declared `[function]` in the `VERIFICATION` module; they are math, used only in the spec.

```
// The exact root set in canonical range [0, P).
syntax Set ::= roots(Int, Int, Int) [function]            // roots(A, N, P)
rule roots(A, N, P) => setFilter(range(0, P), λX . powModP(X, N, P) ==Int (A modInt P))

// X to the N modulo P  (N >= 0); pure math mirror of Python pow(X, N, P).
syntax Int ::= powModP(Int, Int, Int) [function]
rule powModP(X, 0, P) => 1 modInt P
rule powModP(X, N, P) => (X *Int powModP(X, N -Int 1, P)) modInt P   requires N >=Int 1

syntax Bool ::= isPrime(Int) [function]                   // standard primality predicate
```

Intended contract of `nthroot_mod` on the **prime** domain:

```
nthroot_mod(A, N, P, true)  = sortedList(roots(A, N, P))         // all_roots
nthroot_mod(A, N, P, false) = min(roots(A, N, P))                // smallest, when nonempty
nthroot_mod(A, N, P, _)     = None                               // when roots(A,N,P) = {}
```

---

## 3. Mini-X K semantics (fragment actually exercised by the new branch)

Only the constructs on the path to the new branch are modeled. The two solver paths are
collapsed into **one uninterpreted symbol** `solve` with an assumed contract (§4, ASSUME-SOLVE).

```k
// nthroot.k  — mini-Python fragment for nthroot_mod's top-level control flow
module NTHROOT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  syntax Exp  ::= Int | Id | "None"
                | Exp "%"  Exp        [seqstrict]
                | Exp "==" Exp        [seqstrict]
                | "[" Exp "]"                                   // 1-element list literal
                | Exp "if" Exp "else" Exp                        // conditional expression
                | "solve" "(" Exp "," Exp "," Exp "," Exp ")"    // uninterpreted pre-existing solver
                | "sqrtmod" "(" Exp "," Exp "," Exp ")"          // uninterpreted n==2 delegate
  syntax Stmt ::= "if" Exp ":" "return" Exp                      // guarded early return
                | "if" Exp ":" "raise"                           // guarded raise (NotImplementedError)
                | "return" Exp
                | Stmt Stmt           [left]
  syntax KResult ::= Int | Bool
endmodule

module NTHROOT
  imports NTHROOT-SYNTAX
  imports INT
  imports BOOL
  configuration
    <k> $PGM:Stmt </k>
    <env> .Map </env>            // a |-> A, n |-> N, p |-> P, all_roots |-> AR
    <out> .K   </out>            // the returned value / raised marker

  // names and arithmetic
  rule <k> X:Id => V ... </k> <env> ... X |-> V ... </env>
  rule <k> I1:Int %  I2:Int => I1 modInt I2 ... </k> requires I2 =/=Int 0
  rule <k> I1:Int == I2:Int => I1  ==Int I2 ... </k>

  // conditional expression
  rule <k> E1 if true  else _  => E1 ... </k>
  rule <k> _  if false else E2 => E2 ... </k>

  // guarded early return / raise (the guard is evaluated by seqstrict above)
  rule <k> if true  : return E   ~> _ => return E ... </k>
  rule <k> if false : return _   => .K ... </k>     // fall through to next stmt
  rule <k> if true  : raise      ~> _ => .K </k> <out> _ => raised </out>
  rule <k> if false : raise      => .K ... </k>

  // terminal return
  rule <k> return E ~> _ => .K </k> <out> _ => E </out>
  rule <k> return E       => .K </k> <out> _ => E </out>
endmodule
```

The literal `nthroot_mod` body, reduced to its top-level guard chain, is the program
`PGM_nthroot` (each Python guard is one `Stmt`; `is_nthpow_residue`/`isprime` are evaluated
to the symbolic booleans named in the precondition):

```
// n == 2 already returned before this point (separate claim, see L8/CLAIM-SQRT)
if (not isNthPowResidue) : return None       // L7
if (not isPrime(p))      : raise             // L6
if (a % p == 0)          : return ([0] if all_roots else 0)    // ← THE NEW BRANCH (V1)
return solve(a, n, p, all_roots)             // pre-existing paths, ASSUME-SOLVE
```

---

## 4. The claims (reachability rules over the fragment)

### CLAIM-ZERO  — the new branch (the property this audit verifies)

```k
// SPEC-PROVENANCE:
// - from_prompt (L1,L2,L3): a%p==0 ⟹ 0 is a root and must be returned.
// - from_docs   (L4,L5): result must be THE complete root set; smallest if not all_roots.
// - from_code   (L6): reached only after isPrime(p) holds (composite p raised already).
// - key VC: roots(A,N,P) == {0}  (Euclid's lemma; discharged in PROOF.md, PO-ONLY).
claim
  <k> PGM_nthroot => .K </k>
  <env> a |-> A  n |-> N  p |-> P  all_roots |-> AR </env>
  <out> _ => #if AR ==Bool true #then ListItem(0) #else 0 #fi </out>
  requires isPrime(P)
   andBool N >=Int 1
   andBool (A modInt P ==Int 0)
  ensures  roots(A, N, P) ==K SetItem(0)         // ⇒ returned value is the complete, correct answer
  [all-path]
```

### CLAIM-RESIDUE-GUARD (frame, L7) — when no root exists, `None`

```k
claim <k> PGM_nthroot => .K </k>
  <env> a|->A n|->N p|->P all_roots|->AR </env>
  <out> _ => None </out>
  requires notBool isNthPowResidue(A,N,P) [all-path]
```

### CLAIM-PRIME-GUARD (frame, L6) — composite `p` still raises

```k
claim <k> PGM_nthroot => .K </k>
  <env> a|->A n|->N p|->P all_roots|->AR </env>
  <out> _ => raised </out>
  requires isNthPowResidue(A,N,P) andBool notBool isPrime(P) [all-path]
```

### ASSUME-SOLVE (the pre-existing complementary domain — assumed, not re-proved)

```k
// [trusted-on-domain]  a % p != 0:  the untouched _nthroot_mod1 / gcd paths are assumed to
// return the correct roots(A,N,P) (separately tested; see test_residue.py:166-187).
// This audit changes nothing here, so it is assumed rather than re-derived.
claim <k> solve(A,N,P,AR) => sortedOrMin(roots(A,N,P), AR) </k>
  requires isPrime(P) andBool (A modInt P =/=Int 0) andBool isNthPowResidue(A,N,P)
  [trusted]
```

### CLAIM-SQRT (frame, L8) — `n == 2` delegated, also correct for `a ≡ 0`

`n == 2` returns `sqrt_mod(a, p, all_roots)` *before* the guard chain. `sqrt_mod_iter`
(lines 323–326) special-cases `a % p == 0` via `_sqrt_mod1(0, p, 1)`, which yields exactly
`[0]`. So for `a ≡ 0`, the `n==2` path returns `0`/`[0]` — **consistent** with CLAIM-ZERO.
Recorded as a frame obligation, not re-proved (delegated, pre-existing, tested).

---

## 5. Escalation boundary (honest limits)

- **Full correctness of `_nthroot_mod1` and the gcd-on-exponents loop** (the `a%p≠0`
  domain) needs primitive-root theory, discrete-log correctness, and the structure of
  `(Z/pZ)*` — far beyond the bundled arithmetic tier. Marked `[ESCALATION BOUNDARY]`;
  assumed via ASSUME-SOLVE. **Not** faked as proven.
- **The single VC of CLAIM-ZERO**, `roots(A,N,P) = {0}`, reduces to **Euclid's lemma**
  (`P prime ∧ N≥1 ∧ P | X^N ⟹ P | X`). This is elementary and is discharged *by hand* in
  `PROOF.md`; a *machine* discharge would need an inductive primality theory in K, so the
  machine step is itself an `[ESCALATION BOUNDARY]` while the math is certain.

---

## 6. Human-readable spec note

`nthroot_mod(a, n, p, all_roots)` returns the solutions of `x**n ≡ a (mod p)` in `[0, p)`
(`p` prime; composite `p` raises `NotImplementedError`; `None` when there is no solution).

The fix concerns exactly the case **`a` is a multiple of `p`** (`a % p == 0`). Then:

- `0` is a solution, because `0**n = 0 ≡ a (mod p)` for every `n ≥ 1`; and
- for **prime** `p` it is the *only* solution, because `p | x**n ⟹ p | x ⟹ x = 0` in `[0,p)`.

So the complete answer is `0` (smallest root) / `[0]` (all roots). The branch returns
exactly that. It is reached only after `p` has been confirmed prime and after the residue
check (which guarantees `n ≥ 1` on this path — `n = 0` returns `None` earlier, `n = 2` is
delegated to `sqrt_mod` earlier, `n < 0` raises in `is_nthpow_residue`). Both preconditions
of the math (prime `p`, `n ≥ 1`) are therefore enforced upstream of the branch.
