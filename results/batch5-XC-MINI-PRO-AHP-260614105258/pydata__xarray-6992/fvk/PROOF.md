# PROOF — `reset_index` preserves `coord_names ⊆ keys(variables)`

**Constructed, NOT machine-checked.** This write-up constructs the proof by
symbolic execution over the mini-X fragment in `reset_index.k` against the claim
in `reset_index-spec.k`, and emits the `kompile`/`kprove` commands to confirm it
later. Artifacts: `fvk/reset_index.k` (semantics), `fvk/reset_index-spec.k`
(claim + lemmas).

Notation: `V,C,D,N` as in `SPEC.md` §3; `Vk = (V−D)∪N`, `Cn = (C−D)∪N`.

---

## 1. What is proved

> **Function contract (`reset_index` tail).** For all finite name-sets
> `V, C, D, N` with `C ⊆ V`, the fixed body computes `Vk = (V−D)∪N` and
> `Cn = (C−D)∪N` and `Cn ⊆ Vk` holds. Equivalently
> `len(variables) − len(coord_names) ≥ 0`, so `DataVariables.__len__` cannot
> raise.

There is **no loop circularity** in this proof: the relevant computation is
straight-line bulk set algebra (see §4 for why the Python `for`-loop is
soundly abstracted). The "invariant" of the issue is a *class* invariant (INV),
discharged here as a preservation lemma.

## 2. The proof (English)

Goal `PO1`: `(C−D)∪N ⊆ (V−D)∪N`, assuming `C ⊆ V`.

Let `x ∈ (C−D)∪N`. Two cases (definition of `∪`):

1. `x ∈ N`. Then `x ∈ (V−D)∪N` immediately (right operand of `∪`). [lemma L2]
2. `x ∈ C−D`, i.e. `x ∈ C ∧ x ∉ D`. From the precondition `C ⊆ V`, `x ∈ V`.
   With `x ∉ D`, `x ∈ V−D`, hence `x ∈ (V−D)∪N` (left operand). [lemmas L1, L2]

Both cases land in `(V−D)∪N`, so `(C−D)∪N ⊆ (V−D)∪N`. ∎

Two derived facts:

- **`__len__ ≥ 0` (PO5).** `Cn ⊆ Vk` and both finite ⇒ `|Cn| ≤ |Vk|` ⇒
  `|Vk| − |Cn| ≥ 0`. This *is* `len(_variables) − len(_coord_names)`.
- **P2 / PO2 (created coords stay coords).** `N ⊆ Cn` because `N` is the right
  operand of the outer `∪` in `Cn=(C−D)∪N` — true **even if `N ∩ D ≠ ∅`**, since
  `−D` is applied to `C` *before* the union with `N`. This is precisely the
  property the V1 form `Cn=(N∪C)−D` loses (there `−D` is applied *after* adding
  `N`, deleting `N∩D` from the coords). See §5.

## 3. Discharging the MVCE (PO6)

`ds = xr.Dataset(coords={"a": ("x",…), "b": ("x",…)})`
`ds.set_index(z=['a','b']).reset_index("z", drop=True)`:

`set_index` ⇒ `V = C = {z,a,b}` (dim `z`). `reset_index("z", drop=True)`: `z` is
the dim, so the level "keep" path is skipped ⇒ `N = ∅`; `drop=True` ⇒ `D = {z}`.

```
Vk = (V − D) ∪ N = ({z,a,b} − {z}) ∪ ∅ = {a,b}
Cn = (C − D) ∪ N = ({z,a,b} − {z}) ∪ ∅ = {a,b}
Cn ⊆ Vk ✓     __len__ = |{a,b}| − |{a,b}| = 0 ≥ 0 ✓
```

No `ValueError`; the resulting Dataset has coords `a, b` (plain, no index) and
zero data variables — repr works. (Pre-V1: `Cn = {z,a,b} ⊄ {a,b}`, `__len__=−1`.)

## 4. Symbolic-execution sketch & the loop abstraction (PO8)

**Why the loop is abstracted, soundly.** `reset_index`'s `for name in
dims_or_levels` loop writes only `drop_indexes, drop_variables, replaced_indexes,
new_indexes, new_variables`. It **never** touches `coord_names` or `variables`,
which are computed *after* the loop from `self._variables`, `self._coord_names`,
`drop_variables` (`D`), and `new_variables` (`N`). The obligations PO1–PO5 are
quantified over **arbitrary finite `D, N`** (the claim's `D:Set, N:Set` are
symbolic), so they hold for whatever sets the loop produces. Hence modelling the
loop by its outputs `(D, N)` loses nothing for the invariant. (The *values* of
`D, N` — full semantic correctness — is PO9, out of scope.)

**Symbolic run of `reset_index-spec.k`'s claim** (cells `<k>`,`<store>`; store
holds `pv↦V, pc↦C, pd↦D, pn↦N`):

```
vk = (pv - pd) | pn ;   -- seqstrict: lookup pv→V, pd→D ; (V -Set D) ; lookup pn→N ; |Set
                        -- store: vk ↦ (V -Set D) |Set N         [= Vk]
cn = (pc - pd) | pn ;   -- analogously
                        -- store: cn ↦ (C -Set D) |Set N         [= Cn]
return cn <= vk ;       -- lookup cn→Cn, vk→Vk ; rule <=  ⇒  (Cn -Set Vk) ==K .Set
                        -- VC:  (Cn -Set Vk) ==K .Set   under requires subset(C, V)
```

The `<=` rule rewrites the subset test to `(Cn −Set Vk) ==K .Set`. The residual
**verification condition** is

```
VC :  ((C -Set D) |Set N)  -Set  ((V -Set D) |Set N)   ==K   .Set      [requires  subset(C,V)]
```

i.e. `Cn ⊆ Vk`. It is discharged by the §2 case split, realised through the three
`[simplification]` lemmas in `reset_index-spec.k`:

- **L2** `subset(A, A|Y) => true`, `subset(B, X|B) => true` — union supersets
  (cases 1 and the tail of case 2);
- **L1** `subset(A−D, B−D) => true requires subset(A,B)` — difference is monotone
  (case 2: `C ⊆ V ⇒ C−D ⊆ V−D`);
- **L3** `subset(A|N, B|N) => true requires subset(A,B)` — union monotone in the
  left operand against a shared `N` (combines L1+L2 to the full goal:
  `C−D ⊆ V−D ⇒ (C−D)|N ⊆ (V−D)|N`).

Chaining: `subset(C,V)` —L1→ `subset(C−D, V−D)` —L3→
`subset((C−D)|N, (V−D)|N)` ≡ `subset(Cn, Vk)` ⇒ `(Cn −Set Vk) ==K .Set` ⇒ goal
`=> true`. These are first-order facts of the theory of finite sets (Boolean
algebra of sets); an SMT backend with the array/set theory discharges them
directly, and the lemmas make the rewrite explicit for `kprove`. No nonlinear
arithmetic, no induction, no `[trusted]` admits.

## 5. The V1→V2 decision, made by the proof

The VC isolates the exact difference between the two candidate fixes:

| form | `Cn` | PO1 (`Cn⊆Vk`) | PO2 (`N⊆Cn`) | on `N∩D=∅` |
|---|---|---|---|---|
| pre-fix | `N ∪ C` | ✗ (F1) | ✓ | — |
| V1 | `(N ∪ C) − D` | ✓ | **✗ if `N∩D≠∅`** | `= (C−D)∪N` |
| **V2 (chosen)** | `(C − D) ∪ N` | ✓ | ✓ | `= (N∪C)−D` |

V1 and V2 are **provably equal when `N ∩ D = ∅`** (set algebra:
`(N∪C)−D = (N−D)∪(C−D) = N∪(C−D)` when `N∩D=∅`), which covers every realistic and
tested input (the MVCE has `N=∅`). They diverge only on FINDINGS F3's corner,
where V2 additionally satisfies PO2. V2 also makes `reset_index` use the *same*
expression as `set_index` (line 4102). Hence V2 dominates V1: equal on-domain,
strictly more consistent off-domain, and idiom-unifying.

## 6. Run-commands (to upgrade "constructed" → "machine-checked")

```sh
kompile fvk/reset_index.k --backend haskell           # compile the fragment semantics
kast    --backend haskell fvk/reset_index-spec.k      # (optional) confirm the claim parses
kprove  fvk/reset_index-spec.k                         # discharge the claim; expected: #Top
```

Expected result: **`#Top`** (claim proved). Until then this proof is **constructed,
not machine-checked**.

## 7. Test-redundancy (benefit 1) — recommendation only, NEVER auto-delete

Mapping existing tests onto the proved contract:

- **Subsumed by PO1/PO5 once machine-checked** (they assert a single in-domain
  instance of "the resulting Dataset is well-formed / `len` works"):
  the `reset_index(..., drop=True)` consistency aspect of
  `test_dataset.py::test_reset_index`, `test_dataarray.py::test_reset_index`
  (case 5 + array variant), and the `reset_index("id", drop=True)` step inside
  `test_groupby.py`'s reduction pipeline. Reason: each is one concrete `(V,C,D,N)`
  point of the universally-proved `Cn ⊆ Vk`.
- **KEEP regardless** (out of the proved unit / pin orthogonal behaviour):
  - the **value** assertions in those tests (exact coords/levels kept, index types,
    attrs preserved) — these pin PO9 *semantic* behaviour the proof leaves open;
  - `drop=False` cases 1–4 and `test_reset_index_keep_attrs` — PO4 says unchanged,
    but they guard the multi-index *level* recreation values (PO9), not INV;
  - `test_units` / `test_sparse` `reset_index` paths — integration/dtype coverage.

**Conditioning (honesty gate):** these removals are valid **only after**
`kprove` returns `#Top` on `reset_index-spec.k`. Until then, **keep all tests**.
This step recommends; it does not edit tests. Estimated CI saving is negligible
here (a handful of assertions), so the realistic recommendation is **keep
everything** — the value of this proof is the *bug/consistency* finding (benefit
2), not test pruning.

## 8. Residual risk

- **Constructed, not machine-checked** (§6). The set-theory VC is elementary, so
  confidence is high, but `#Top` is not yet obtained.
- **Trusted base:** adequacy of the mini-X fragment and of abstracting the loop by
  `(D,N)` (PO8, justified §4); the reachability metatheory / `kprove`; the
  SMT/set-theory + `[simplification]` oracle.
- **Precondition `C ⊆ V`** is assumed (the input class invariant, F4/F6), not
  re-checked by `reset_index`.
- **Partial correctness** only (termination trivial here — straight-line + finite
  iteration — so this is not a real gap).
- **PO9** (full keep/drop value semantics) is deliberately out of scope; the
  invariant holds independently of it (§4).
