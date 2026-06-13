# PROOF (constructed, not machine-checked) — astropy#13398 ITRS↔Observed

This constructs the correctness proof for the `SPEC.md` contracts, discharging the
`PROOF_OBLIGATIONS.md` VCs. **No execution environment** is used; per the kit's
honesty gate everything is labeled *constructed, not machine-checked*, and the
real-arithmetic VCs are routed as `[ESCALATION BOUNDARY]`, **not** faked as
`[trusted]`.

## §0 — Shape: no loops, no recursion ⇒ no circularities

`itrs_to_observed_mat`, `itrs_to_observed`, `observed_to_itrs` are **straight-line**
linear algebra (a matrix build, one matrix–vector product, vector ± vector, a
transpose). There is **no `while`/`for` and no recursion**, so the Circularity rule
(the coinductive loop/recursion hypothesis) **does not apply** — there is nothing to
generalize over an accumulator/counter. The proof is by **direct symbolic execution +
Consequence (arithmetic VCs)** only. Termination is trivial (no back-edge); partial
correctness = total correctness here.

This is *outside* the bundled mini-X sweet spot (integer counting loops). The code is
**real linear algebra**; the faithful semantics needs ℝ-valued 3-vectors and 3×3
matrices. We therefore build a small **mini-linalg** fragment (below), state the
claims over it, discharge what is equational/linear, and mark the trigonometric facts
`[ESC]`.

## §1 — Mini-linalg K fragment (`fvk/itrs_observed.k`, sketch)

> Constructed, not machine-checked. Models exactly the operations the code uses.
> Reals/trig exceed the bundled INT tier — declared as an escalation boundary for
> `kprove` (route to a real-closed-field theory); used here for the algebraic proof.

```k
module ITRS-OBSERVED-SYNTAX
  imports REAL          // [ESC]: real arithmetic (not bundled INT); +Real,*Real,sqrtReal,sinReal,cosReal
  // Vectors and matrices as fixed-shape tuples (value sorts, no heap/aliasing)
  syntax Vec ::= "v(" Real "," Real "," Real ")"
  syntax Mat ::= "m(" Real "," Real "," Real ","      // row 0
                      Real "," Real "," Real ","      // row 1
                      Real "," Real "," Real ")"      // row 2
  // Operations actually used by the code:
  syntax Vec ::= mxv(Mat, Vec)        [function]   // M @ v  == CartesianRepresentation.transform (erfa rxp)
                | vsub(Vec, Vec)       [function]   // P - L
                | vadd(Vec, Vec)       [function]   // topo + L
  syntax Mat ::= mxm(Mat, Mat)        [function]   // matrix product (for building M and proving M·Mᵀ)
                | transp(Mat)          [function]   // matrix_transpose
                | Rz(Real) | Ry(Real)              // rotation_matrix(.,'z'/'y')
                | minusX | minusY | eye  [function] // diag(-1,1,1) / diag(1,-1,1) / I
  syntax Real ::= norm(Vec)           [function]
  syntax KResult ::= Vec | Mat | Real
endmodule

module ITRS-OBSERVED
  imports ITRS-OBSERVED-SYNTAX
  // mxv = the three dot products (faithful to erfa rxp, column-vector convention)
  rule mxv(m(A,B,C, D,E,F, G,H,I), v(X,Y,Z))
    => v(A*Real X +Real B*Real Y +Real C*Real Z,
         D*Real X +Real E*Real Y +Real F*Real Z,
         G*Real X +Real H*Real Y +Real I*Real Z)
  rule vsub(v(X1,Y1,Z1), v(X2,Y2,Z2)) => v(X1 -Real X2, Y1 -Real Y2, Z1 -Real Z2)
  rule vadd(v(X1,Y1,Z1), v(X2,Y2,Z2)) => v(X1 +Real X2, Y1 +Real Y2, Z1 +Real Z2)
  rule transp(m(A,B,C, D,E,F, G,H,I)) => m(A,D,G, B,E,H, C,F,I)
  rule minusX => m(-1,0,0, 0,1,0, 0,0,1)
  rule minusY => m(1,0,0, 0,-1,0, 0,0,1)
  rule eye    => m(1,0,0, 0,1,0, 0,0,1)
  // rotation_matrix(L,'z'): proper rotation about z (matches matrix_utilities.rotation_matrix)
  rule Rz(L) => m( cosReal(L), sinReal(L), 0,
                  (0 -Real sinReal(L)), cosReal(L), 0,
                   0, 0, 1)
  // rotation_matrix(A,'y')
  rule Ry(A) => m( cosReal(A), 0, (0 -Real sinReal(A)),
                   0, 1, 0,
                   sinReal(A), 0, cosReal(A))
  // mxm: 9 dot products (used to evaluate M = minusX·Ry·Rz and M·Mᵀ). [standard, omitted]
  rule norm(v(X,Y,Z)) => sqrtReal(X*Real X +Real Y*Real Y +Real Z*Real Z)
endmodule
```

The two transform functions are modeled as the composite terms the Python builds:

```
itrs_to_observed_mat(AltAz@(L,P_))  ==  mxm(minusX, mxm(Ry(PIOVER2 -Real P_), Rz(L)))   // P_ = latitude φ
itrs_to_observed_mat(HADec@(L,_))   ==  mxm(minusY, Rz(L))
itrs_to_observed(P, frame)          ==  mxv( M , vsub(P, Lvec) )                          // M as above
observed_to_itrs(Q, frame)          ==  vadd( mxv( transp(M) , Q) , Lvec )
```

## §2 — Claims (`fvk/itrs_observed-spec.k`, sketch)

> `[all-path]`; deterministic (pure functions) so all-path = one-path. Symbolic
> `L`(=λ), `F`(=φ), `P=v(Px,Py,Pz)`, `Q`, `Lvec`.

```k
// (ORTHO-A)  M_A · M_Aᵀ = I
claim <k> mxm(MA, transp(MA)) => eye </k>
  requires MA ==K mxm(minusX, mxm(Ry(PIOVER2 -Real F), Rz(L)))            // [ESC] trig

// (ORTHO-H)  M_H · M_Hᵀ = I
claim <k> mxm(MH, transp(MH)) => eye </k>
  requires MH ==K mxm(minusY, Rz(L))                                       // [ESC] trig

// (ROUNDTRIP-IO)  observed_to_itrs(itrs_to_observed(P)) = P
claim <k> vadd(mxv(transp(M), mxv(M, vsub(P, Lvec))), Lvec) => P </k>
  requires M ==K MA  orBool  M ==K MH                                      // via ORTHO-*

// (ROUNDTRIP-OI)  itrs_to_observed(observed_to_itrs(Q)) = Q
claim <k> mxv(M, vsub(vadd(mxv(transp(M), Q), Lvec), Lvec)) => Q </k>
  requires M ==K MA  orBool  M ==K MH

// (ANCHOR-A-UP)  M_A · up = (0,0,1)
claim <k> mxv(MA, v(cosReal(F)*Real cosReal(L), cosReal(F)*Real sinReal(L), sinReal(F)))
       => v(0,0,1) </k>                                                    // [ESC] trig
// ... ANCHOR-A-NORTH, ANCHOR-A-EAST, ANCHOR-H-* analogous (PO5/PO6) ...
```

`[simplification]` lemmas supplied (the linear-algebra analogues of the sum example's
arithmetic lemmas):

```k
rule sinReal(T) *Real sinReal(T) +Real cosReal(T) *Real cosReal(T) => 1   [simplification]  // [ESC]
rule cosReal(PIOVER2 -Real F) => sinReal(F)                               [simplification]  // [ESC]
rule sinReal(PIOVER2 -Real F) => cosReal(F)                               [simplification]  // [ESC]
// map-extensionality analogue to close cell equalities, as in k-framework.md §6
```

## §3 — Constructed proofs

### §3.0 Orthogonality (PO1/PO2) — the algebraic core

By **L-ROT**, each `Rz(L)`, `Ry(A)` satisfies `Rᵀ·R = I` (symbolic-execute
`mxm(transp(Rz(L)), Rz(L))`; the diagonal entries cool to
`cos²L + sin²L`, `cos²L + sin²L`, `1`, off-diagonals to `0`; apply the `sin²+cos²=1`
`[simplification]` ⇒ `eye`). By **L-REFL**, `minusXᵀ·minusX = eye` and
`minusYᵀ·minusY = eye` (diagonal ±1; pure `Z3`). By **L-PROD**, for `M = minusX·Ry·Rz`:

```
Mᵀ·M = (minusX·Ry·Rz)ᵀ·(minusX·Ry·Rz)
     = Rzᵀ·Ryᵀ·minusXᵀ·minusX·Ry·Rz
     = Rzᵀ·Ryᵀ·(I)·Ry·Rz   [L-REFL]
     = Rzᵀ·(Ryᵀ·Ry)·Rz = Rzᵀ·I·Rz = Rzᵀ·Rz = I   [L-ROT ×2]
```

⇒ **(ORTHO-A)** `M_A Mᵀ_A = M_Aᵀ M_A = I`. Identically for **(ORTHO-H)** with `minusY`
and a single `Rz`. `det M = ∓1` from the reflection factor ⇒ left-handed. ∎
*Discharge tier:* `[SIMP]` (`sin²+cos²=1`) + `Z3` equational; the general real-trig
closure is `[ESC]` — stated, routed, hand-checked above.

### §3.1 AltAz anchors (PO5) — symbolic execution of `mxv`

`up = v(cosφ cosλ, cosφ sinλ, sinφ)`. Apply `Rz(λ)` (cool the three dot products):
`Rz(λ)·up = v(cosφ, 0, sinφ)` using `cos²λ+sin²λ=1`. Apply `Ry(π/2−φ)` with
`cos(π/2−φ)=sinφ`, `sin(π/2−φ)=cosφ`:
`Ry·v(cosφ,0,sinφ) = v(sinφ·cosφ − cosφ·sinφ, 0, cosφ·cosφ + sinφ·sinφ) = v(0,0,1)`.
Apply `minusX`: `v(0,0,1)`. ⇒ alt = 90°. ∎
North `v(−sinφcosλ,−sinφsinλ,cosφ)` ⇒ `Rz`→`v(−sinφ,0,cosφ)` ⇒ `Ry`→`v(−1,0,0)` ⇒
`minusX`→`v(1,0,0)` ⇒ az 0°, alt 0°.
East `v(−sinλ,cosλ,0)` ⇒ `Rz`→`v(0,1,0)` ⇒ `Ry`→`v(0,1,0)` ⇒ `minusX`→`v(0,1,0)` ⇒
az 90°, alt 0° (East-of-North ✓). ∎  *Tier:* `[ESC]` trig, hand-discharged.

### §3.2 HADec anchors (PO6)

`merid_eq = v(cosλ,sinλ,0)` ⇒ `Rz(λ)`→`v(1,0,0)` ⇒ `minusY`→`v(1,0,0)` ⇒ ha 0, dec 0.
`pole = v(0,0,1)` ⇒ `Rz`→`v(0,0,1)` ⇒ `minusY`→`v(0,0,1)` ⇒ dec 90°.
`east = v(−sinλ,cosλ,0)` ⇒ `Rz`→`v(0,1,0)` ⇒ `minusY`→`v(0,−1,0)` ⇒ ha −6ʰ (negative
to the East ✓). ∎  *Tier:* `[ESC]` trig, hand-discharged.

### §3.3 Round-trips (PO3/PO4) — Consequence using ORTHO as lemmas

Symbolic-execute **(ROUNDTRIP-IO)**:
`vadd(mxv(transp(M), mxv(M, vsub(P,Lvec))), Lvec)`
→ `mxv(transp(M), mxv(M, W))` where `W = P−Lvec`
→ `mxv(mxm(transp(M),M), W)` (associativity of `mxv∘mxv` = `mxv` of `mxm`, a rule of
the fragment) → by **(ORTHO-*)** `mxm(transp(M),M) ⇒ eye` → `mxv(eye,W) ⇒ W` → `vadd(W,Lvec) ⇒ vadd(vsub(P,Lvec),Lvec) ⇒ P`. ∎ **Exact.**
**(ROUNDTRIP-OI)** identically with `M·Mᵀ = eye`. ∎ These are the cleanest VCs and are
pure `Z3`/equational **once ORTHO is granted** — no trig leaks into the round-trip
itself (the trig is entirely encapsulated in ORTHO).

### §3.4 Norm / topocentricity (PO7)

`norm(mxv(M, W))² = Wᵀ·(MᵀM)·W = Wᵀ·W = norm(W)²` by ORTHO. ⇒ output range = observer→
target distance. ∎ `Z3` given ORTHO.

### §4 — `obstime`-independence & velocity (PO8) — justifies the V2 edit

**PO8a.** Data-flow inspection: `itrs_to_observed`/`observed_to_itrs` reference only
`*.cartesian`, `*.location` (→ geodetic λ,φ and the location's fixed ITRS cartesian).
**No `obstime` is read.** ⇒ outputs invariant under any `obstime` change. ∎
**PO8b.** The `FunctionTransformWithFiniteDifference` induced term evaluates `supcall`
at `obstime ± Δ/2`. By PO8a these are bit-identical ⇒ difference `= 0.0` exactly. ∎
**PO8c.** `X ↦ mxv(M, vsub(X,L))` is affine, `M,L` constant ⇒
`(f(P+VΔ) − f(P−VΔ))/2Δ = mxv(M,V)` exactly. ∎
**Therefore** `finite_difference_frameattr_name=None` (V2) deletes only the `0.0` PO8b
term: results are **bit-identical** to V1 wherever V1 returned, and V1's `None + Δ`
crash (Finding 4) is removed. This is the proof that the *one* V2 code change is safe.

## §5 — Residual risk (honesty gate)

- **Constructed, not machine-checked.** No `kompile`/`kprove` was run (no environment).
  Run-commands in §6.
- **Trusted base:** (i) adequacy of the mini-linalg fragment as a model of
  numpy/erfa `rxp`/`rotation_matrix` (faithful for the ops used; floating-point is
  idealized to ℝ — the proofs are exact in ℝ, real code carries ~1e-15 rounding,
  which is why the existing tests use `atol`); (ii) the reachability metatheory +
  `kprove`; (iii) the SMT/`[simplification]` oracle.
- **Escalation boundary:** PO1/PO2/PO5/PO6 rest on real-trigonometric identities
  (`sin²+cos²=1`, complementary angles) **outside** the bundled INT tier. They are
  standard, hand-verified here, and routed (real-closed-field / linear-algebra theory)
  — **not** admitted as `[trusted]`. The round-trips PO3/PO4 (the headline property)
  reduce to pure equational reasoning once ORTHO is granted.
- **Partial vs total:** N/A distinction — straight-line code, terminates trivially.

## §6 — Run-commands (to upgrade *constructed* → *machine-checked*)

```sh
kompile fvk/itrs_observed.k --backend haskell          # needs a REAL-arithmetic theory; [ESC]
kast    --backend haskell fvk/itrs_observed-spec.k     # (optional) parse-check the claims
kprove  fvk/itrs_observed-spec.k                        # expected #Top for PO3/PO4/PO7/PO8;
                                                        # PO1/PO2/PO5/PO6 need the real-trig lemmas loaded
```

## §7 — Test-redundancy (benefit 1) — recommendation only, conditioned on machine-check

Once the contract is machine-checked, these become **subsumed** (do **not** auto-delete
— astropy's suite is fixed/hidden here; this is advisory):

- **Round-trip unit tests** (`ITRS→AltAz→ITRS`, `ITRS→HADec→ITRS` exact-position checks)
  → subsumed by **PO3/PO4** (`MᵀM = I`), for *every* in-domain position.
- **Single-geometry checks** (e.g. straight-overhead alt=90°, ha=0/dec=lat) → subsumed
  by the **PO5/PO6 anchors**, which hold for all `λ,φ`.

**Keep (not subsumed):** out-of-domain/error tests (no-distance, `location=None` —
Findings 1,2; these pin fail-safe behavior **outside** the verified domain); any
velocity test with `obstime=None` (pins Finding-4 behavior); integration tests through
the transform graph (path selection, `obstime` adoption); and float-tolerance tests
(the proof is exact in ℝ; rounding is in the trusted base). **Termination tests:** none
needed (straight-line).

## §8 — Two plain-language payoffs

- **Benefit 2 (bugs/edges):** surfaced the no-distance and `location=None` preconditions
  and the **moving-object + `obstime=None` crash** (Finding 4, fixed) — and *proved* the
  geometry and round-trips correct, so reviewers get assurance without reading K.
- **Benefit 1 (fewer tests):** round-trip and single-geometry unit tests are provably
  redundant on the verified domain (conditioned on machine-checking the `[ESC]` trig
  lemmas).
