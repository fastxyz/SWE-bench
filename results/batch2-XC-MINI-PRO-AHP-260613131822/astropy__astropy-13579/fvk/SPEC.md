# SPEC.md — formal specification of `SlicedLowLevelWCS.world_to_pixel_values`

Target: `astropy/wcs/wcsapi/wrappers/sliced_wcs.py`,
`SlicedLowLevelWCS.world_to_pixel_values` (and the helper
`_pixel_to_world_values_all` it now calls).

This is the FVK *intent-spec* for the method, written against the V1 fix that is
applied in `repo/`. It is partial-correctness (correct *if* it returns; the
underlying numerical solver's termination is out of scope) and it is honest about
its **trusted base**: the numerical inversion performed by the wrapped WCS
(`self._wcs.world_to_pixel_values`, ultimately WCSLIB + projection math) is an
**external oracle**, not provable from this Python source — see the
`[ESCALATION BOUNDARY]` in §6 and `PROOF_OBLIGATIONS.md`.

---

## 1. What the code is supposed to do (intent)

`SlicedLowLevelWCS` applies an array slice to a WCS, dropping the sliced-out
pixel and (correlated) world dimensions. It must satisfy the APE-14 low-level
WCS contract. The relevant part of that contract for this method is the
**round-trip / inverse** relationship with `pixel_to_world_values`:

> Intent (R): For a sliced WCS `sl`, `world_to_pixel_values` must invert
> `pixel_to_world_values` on the sliced frame, consistent with the underlying
> WCS evaluated *at the slice location*. Concretely, for any kept-pixel vector
> `a` in the invertible domain,
> `sl.world_to_pixel_values(*sl.pixel_to_world_values(*a)) == a`.

The issue (`PROBLEM.md`) is a direct violation of (R): with a `PCij` matrix that
couples the spectral and a spatial axis, slicing one wavelength plane made
`world_to_pixel_values` return `~1.8e11` for a kept spatial axis instead of the
round-trip value.

The minimal reproducer encodes (R) exactly:

```python
sl    = SlicedLowLevelWCS(fits_wcs, 0)
world = fits_wcs.pixel_to_world_values(0, 0, 0)
out   = sl.world_to_pixel_values(world[0], world[1])
assert np.allclose(out[0], 0)         # (R) at a = (0, 0)
```

## 2. Abstractions / notation

Let the wrapped WCS `W = self._wcs` have `npix` pixel axes and `nworld` world
axes, with

- `F  := W.pixel_to_world_values : R^npix -> R^nworld`   (forward),
- `G  := W.world_to_pixel_values : R^nworld -> R^npix`    (inverse).

The slice fixes a set of **dropped** pixel axes `Dpix` at integer indices, plus
optional `slice.start` offsets `o_i` on **kept** pixel axes `Kpix`
(`m := |Kpix| = self.pixel_n_dim`). The correlation matrix induces **dropped**
world axes `Dworld` and **kept** world axes `Kworld`
(`r := |Kworld| = self.world_n_dim`). `self._world_keep` / `self._pixel_keep`
are the sorted kept index lists.

Define the *slice embedding* of a kept-pixel vector `a ∈ R^m`:

```
combine_pix(a) ∈ R^npix :   axis i  ↦   a[rank_Kpix(i)] + o_i   if i ∈ Kpix
                                         s_i (integer slice index) if i ∈ Dpix
```

so that `_pixel_to_world_values_all(*a) = F(combine_pix(a))`  (this is exactly
what the helper computes: lines 212–227).

Define the **slice world coordinate**
`d := F(combine_pix(0)) = _pixel_to_world_values_all(*[0]*m)` — the new
`sliced_out_world_coords` (line 246). `d` is an `nworld`-vector; `d[Dworld]` are
the world values the dropped axes take at the slice origin.

The sliced forward and the implemented sliced inverse are:

```
sF(a)      = F(combine_pix(a)) [Kworld]                              # pixel_to_world_values
sG(w_K)    = ( G(embed_world(w_K, d)) [Kpix] ) - offsets            # world_to_pixel_values (V1)
  where embed_world(w_K, d) ∈ R^nworld :
        axis j ↦ w_K[rank_Kworld(j)]   if j ∈ Kworld
                 d[j]                  if j ∈ Dworld
```

The **only change** V1 makes is the dropped-axis fill in `embed_world`: V0 used
the constant `1.` (i.e. `d[j] := 1.0`), V1 uses `d[j]` (the true slice world
value).

## 3. Mini-X semantics (fragment actually used)

The method uses: tuple build, `range`, a `for` loop, membership `in` on a small
index set, integer increment, list `append`, integer-indexed read of an
array/tuple, `np.broadcast_arrays` (shape glue, value-preserving), elementwise
`-=`, and two opaque numerical calls (`F`, `G`). Modeled as mini-Python over a
store of integers/maps plus two uninterpreted function symbols. (`np.asanyarray`
and `np.broadcast_arrays` are modeled as value-preserving coercions: they change
shape, never the represented mathematical value, so they are identities for the
purpose of (R).)

```k
// mini-wcs.k  (fragment; constructed, not machine-checked)
module MINI-WCS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  syntax Exp ::= Int | Id
               | "F" "(" Exp ")"          // wrapped pixel_to_world_values  (opaque)
               | "G" "(" Exp ")"          // wrapped world_to_pixel_values  (opaque)
               | Exp "[" Exp "]"  [strict]      // index read
               | Exp "in" Exp     [seqstrict]   // membership in kept-set
               > Exp "+" Exp      [seqstrict, left]
  syntax Stmt ::= Id "=" Exp ";"  [strict(2)]
               | "append" "(" Id "," Exp ")" ";"          [strict(2)]
               | "for" Id "in" "range" "(" Exp ")" ":" Stmt
               | Stmt Stmt        [left]
  syntax KResult ::= Int | Bool
endmodule

module MINI-WCS
  imports MINI-WCS-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST
  configuration
    <k> $PGM:Stmt </k>
    <store> .Map </store>      // program vars: counters, lists (as index|->value maps)
    <keep>  .Map </keep>       // Kworld / Kpix membership + d (slice world coords)
  // builtin int/bool/index rules elided (standard);
  // F and G are *uninterpreted symbols* constrained only by the oracle axiom (§6).
endmodule
```

`F`/`G` are deliberately uninterpreted; their only property is the inversion
**oracle axiom** of §6. Everything else is ordinary mini-Python stepping.

## 4. Function contract — reachability claim `(W2P)`

```k
// mini-wcs-spec.k  (constructed, not machine-checked)
claim
  <k> world_to_pixel_values(W ; SL ; embed_world(WK , F(combine_pix(0))))
        => .K ... </k>
  <store> result |-> ( ?P:Vec => WK_pixels ) ... </store>
  requires INVERTIBLE(W, combine_pix(A))           // oracle domain (§6)
   andBool DECOUPLE(W, SL)                          // F[Dworld] ⊥ Kpix  (§5, the crux)
   andBool WK ==K sF(A)                             // WK is a genuine forward image
  ensures  WK_pixels ==K A                          // round-trip identity, (R)
  [all-path]
```

Read plainly: **for a sliced WCS whose dropped world axes do not depend on the
kept pixel axes, and inputs `w_K` that are a real forward image `sF(a)` lying in
the invertible domain, `world_to_pixel_values(w_K)` returns exactly `a`.** This
is property (R).

## 5. The two loops — circularity claims

`world_to_pixel_values` contains two bounded `for` loops; each gets a loop
invariant stated as a circularity (generalized over the loop counter).

### `(BUILD)` — the `world_arrays_new` construction loop (lines 251–256)

```k
claim
  <k> for iworld in range(NWORLD): BODY => .K ... </k>
  <store>
     iworld      |-> (K0:Int => NWORLD)
     iworld_curr |-> (#kept(K0) -Int 1 => #kept(NWORLD) -Int 1)
     new         |-> (L:List => L ++ slots(K0, NWORLD))
     ...
  </store>
  requires 0 <=Int K0 andBool K0 <=Int NWORLD
   andBool len(world_arrays) ==Int #kept(NWORLD)        // APE-14 input-count contract
  [all-path]
```

with the invariant content `slots(k0, k1)` = "for each `i` in `[k0, k1)`,
`new[i] = world_arrays[rank_Kworld(i)]` if `i ∈ Kworld`, else `new[i] = d[i]`",
and `iworld_curr` tracking `#kept(iworld) - 1`. The side condition
`len(world_arrays) == #kept(NWORLD) == r` keeps `world_arrays[iworld_curr]`
in-bounds — this is the APE-14 caller contract (exactly `r` world values).

### `(OFFSET)` — the offset-subtraction loop (lines 261–263)

```k
claim
  <k> for ipixel in range(NPIX): SUBOFF => .K ... </k>
  <store> pix |-> (P:Vec => suboffset(P, K0, NPIX)) ... </store>
  requires 0 <=Int K0 andBool K0 <=Int NPIX
  [all-path]
```

invariant: for each `i ∈ [k0, NPIX)`, `pix[i]` has had `o_i` subtracted iff axis
`i` is a `slice` with a non-`None` `start`, else unchanged.

Both loops are finite-range counting loops with no nonlinear arithmetic; the
circularities discharge by guarded coinduction (the counter increment is the
genuine `=>⁺` step) with only linear in-bounds VCs.

## 6. Preconditions, side conditions, and the trusted base

- **`INVERTIBLE(W, combine_pix(A))`** — the wrapped WCS transform is non-degenerate
  at the relevant point so `G` is a genuine inverse there. *Out-of-domain inputs
  (projection singularities, NaN) are outside the contract.*
- **`DECOUPLE(W, SL)`** — the dropped world axes do not depend on the kept pixel
  axes: `F[Dworld](combine_pix(a))` is independent of `a`. Equivalent (for the
  linear `PCij` part) to: the `Dworld × Kpix` block of the coupling is zero.
  **This holds for the issue's WCS** (the spectral world axis depends only on the
  spectral *pixel* axis, `PC3_* = [0,0,1]`), so (R) is *exact* there.
- **Input-count contract** — the caller passes exactly `r = world_n_dim` world
  values (APE-14). Enforced informally; a wrong count is an `IndexError`.
- **`__init__` invariant** — `len(world_keep) >= 1` and `len(pixel_keep) >= 1`
  (lines 152–154). Consequence used by the proof: if `nworld == 1` there is **no**
  dropped world axis, so the `else` branch (line 256) and its
  `sliced_out_world_coords[iworld]` indexing are **unreachable** — which is why we
  may index a possibly-non-tuple return safely (PO5).

- **`[ESCALATION BOUNDARY]` — the inversion oracle.** `F` and `G` come from the
  wrapped WCS (for `astropy.wcs.WCS`: WCSLIB C + an iterative solver for the
  projection). The law `G(F(p)) = p` (and `F(G(w)) = w`) on the invertible domain
  is **assumed**, not proved from this repo. It is the *trusted base*; this kit's
  bundled tier cannot discharge it (it is numerical/iterative, outside mini-X).
  We state it explicitly rather than fake a `[trusted]` proof. Everything above
  the oracle line *is* in scope and is what the proof in `PROOF.md` discharges.

## 7. As-built note (V0 vs V1)

The as-built V0 differs from the spec only at `embed_world`'s dropped slot:
V0 substitutes the constant `1.0` for `d[Dworld]`. Under that substitution
`embed_world(w_K, 1.0) ≠ F(combine_pix(a))` whenever `d[Dworld] ≠ 1.0`
(essentially always, and unit-mismatched: world axes are SI, so `1.0` is `1 m`
for a `WAVE` axis whose true value is `~1.05e-10 m`). Hence
`G(embed_world) ≠ combine_pix(a)` and (R) fails — precisely Finding F1. V1
restores `d[Dworld]`, making the claim's left-hand `<k>` term *equal* to
`F(combine_pix(a))` under `DECOUPLE`, which is what the proof needs.
