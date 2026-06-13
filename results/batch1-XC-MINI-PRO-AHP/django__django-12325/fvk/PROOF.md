# PROOF — parent-link collection loop (constructed, not machine-checked)

Constructed proof of `(FOLD)` and `(SELECT-PL)` from
`fvk/mti_parent_links-spec.k` against the fragment semantics
`fvk/mti_parent_links.k`. **MVP status: constructed, not machine-checked** — the
`kompile`/`kprove` commands (§5) are emitted and reasoned about, **not run** (no
execution environment, per task rules).

What is proved, in one line: **for every parent key, the field this loop records
as the MTI parent link is `parent_link=True` exactly when some declared
`OneToOneField` to that parent is `parent_link=True` — independently of field
declaration order — and otherwise is the last such field; and the set of linked
parents is unchanged from the original code.**

---

## 1. (FOLD) — the loop is the functional fold

**Claim.** `⟨k⟩ select(VS) ⟨plinks⟩ M  ⇒  ⟨k⟩ .K ⟨plinks⟩ foldSel(M, VS)`.

**Proof (guarded coinduction, induction on `VS`).**

- *Base* `VS = .Fields`. Axiom `select(.Fields) => .K` fires; `<plinks>` is
  framed unchanged = `M`. `foldSel(M, .Fields) => M`. Both sides `⟨.K⟩ M`. ∎
  (PO-4, [Z3].)
- *Step* `VS = F ; Rest`. The rule
  `select(F ; Rest) => select(Rest)` with `<plinks> M => updateSel(M, F)` fires —
  one genuine `=>⁺` step, discharging **guardedness**. The goal is now
  `⟨k⟩ select(Rest) ⟨plinks⟩ updateSel(M, F) ⇒ ⟨k⟩ .K ⟨plinks⟩ foldSel(M, F;Rest)`.
  Invoke the **circularity** (the claim itself) at `M := updateSel(M, F)`,
  `VS := Rest`: it gives `foldSel(updateSel(M,F), Rest)`. By `foldSel`'s cons
  rule `foldSel(M, F;Rest) = foldSel(updateSel(M,F), Rest)`, the two coincide.
  (PO-5, [STRUCT].) ∎

`(FOLD)` is arithmetic-free and definitional; expected `#Top` under `kprove`.

## 2. `updateSel` totality and no-crash (PO-1..PO-3)

`skip(M,K,PL)` has three exhaustive, pairwise-exclusive rules keyed on
`K in_keys(M)` and `g ≡ plOf(M[K])==1 ∧ PL==0`; `plOf(M[K])` is evaluated **only**
in the rules guarded by `K in_keys(M)`, so the map read is always defined — the
formal image of Python's short-circuit `existing is not None and
existing.remote_field.parent_link …`. Hence `skip` and `updateSel` are total
(PO-3, [Z3]) and the modelled body never faults (PO-1). `<plinks>` holds only
`Field`s by construction (PO-2, [STRUCT]). These discharge **F-1**.

## 3. (SELECT-PL) — selection correctness, by induction (the heart)

Let `FS = [f_1, …, f_m]` be the candidates for one key `K`
(`candOf(FS,K)=FS`, `m ≥ 1`), folded from an empty slot for `K`. Write `PL_j =
plOf(f_j)`, `chosen_t` = the value at `K` after `f_1..f_t`. **Invariant INV(t):**

1. `chosen_t ∈ {f_1,…,f_t}`                                         (→ I1)
2. `PL(chosen_t) = 1  ⟺  ∃ j ≤ t. PL_j = 1`   (i.e. `anyPL(FS[1..t])`)  (→ I2)
3. `¬anyPL(FS[1..t])  ⇒  chosen_t = f_t`                            (→ I3)

**INV(1)** (PO-6, [Z3]). Slot for `K` empty ⇒ `skip` false (rule 2 of `skip`) ⇒
`updateSel` overwrites ⇒ `chosen_1 = f_1`. (1) `f_1∈{f_1}`✓. (2) `PL(f_1)=1 ⟺
PL_1=1`✓. (3) `chosen_1=f_1`✓.

**INV(t) ⇒ INV(t+1).** Process `f_{t+1}`. `existing = chosen_t` (present, by
INV(t).1). Guard `g ≡ PL(chosen_t)=1 ∧ PL_{t+1}=0`.

- **Skip branch** `g` true: `PL(chosen_t)=1` and `PL_{t+1}=0`; `chosen_{t+1} =
  chosen_t`. (PO-7, [ESC].)
  - (1) `chosen_t ∈ {f_1..f_t} ⊆ {f_1..f_{t+1}}`✓.
  - (2) `PL(chosen_{t+1})=PL(chosen_t)=1`; RHS `anyPL(FS[1..t+1])` is true (witness
    `chosen_t`). `1 ⟺ true`✓.
  - (3) hypothesis `¬anyPL(FS[1..t+1])` is **false** (chosen_t is a witness) ⇒
    vacuous✓.
- **Overwrite branch** `g` false (`PL(chosen_t)=0` **or** `PL_{t+1}=1`):
  `chosen_{t+1} = f_{t+1}`. (PO-8, [ESC].)
  - (1) `f_{t+1} ∈ {f_1..f_{t+1}}`✓.
  - (2) Show `PL(f_{t+1})=1 ⟺ anyPL(FS[1..t+1])`.
    - If `PL_{t+1}=1`: LHS true; RHS true (witness `f_{t+1}`)✓.
    - If `PL_{t+1}=0`: then `g` false forced `PL(chosen_t)=0`; by INV(t).2
      **contrapositive**, `¬anyPL(FS[1..t])`, i.e. no `f_j (j≤t)` is a parent
      link. With `PL_{t+1}=0` too, `anyPL(FS[1..t+1])` is false. LHS `PL(f_{t+1})=0`
      i.e. false. `false ⟺ false`✓. *(This contrapositive step is the crux the
      formalization isolates — it is why I2 must be a **biconditional**, not just
      "chosen is a parent link if some candidate is".)*
  - (3) If `¬anyPL(FS[1..t+1])` then `PL_{t+1}=0` and `chosen_{t+1}=f_{t+1}=f_{t+1}`
    (the last of `FS[1..t+1]`)✓.

**Closure** (PO-9, [Z3]). INV(m) is exactly I1 ∧ I2 ∧ I3 for `FS`. The
biconditional `plOf(chosen)==1 ==Bool anyPL(FS)` is well-typed because every
`PL_j ∈ {0,1}` (PO-10, [Z3]). ∎

**Order independence (the corollary that answers the issue).** If exactly one
`f_p` has `PL_p=1`, then by I2 `chosen` is a parent link, and by I1 `chosen ∈ FS`;
the only parent-link candidate is `f_p`, so `chosen = f_p` — for **every**
ordering of `FS`. The pre-fix code violated this whenever `p ≠ m`.

## 4. (KEY-INDEP) — lifting one key to the interleaved list

**Lemma.** `foldSel(.Map, VS)[K] = foldSel(.Map, candOf(VS,K))[K]` and
`K ∈ keys(foldSel(.Map,VS)) ⟺ K ∈ keysOf(VS)`.

**Proof (induction on `VS`; PO-11/PO-12, [ESC]/[STRUCT]).** `updateSel(M,
field(K',·,·))` rewrites only entry `K'` (`M[K' <- …]` or `M`); for `K' ≠ K` it
leaves `M[K]` and `K∈keys(M)` untouched. So folding `VS` affects key `K` exactly
through its `K`-subsequence `candOf(VS,K)`, and inserts a key iff that key is
visited. Thus §3's single-key result holds for every key of the interleaved
`VS`, giving SPEC clauses I1–I3 for all keys and **D** (`keys = keysOf(VS)`). ∎

`(KEY-INDEP)` + `(SELECT-PL)` together are the full SPEC postcondition.

## 5. Machine-check commands (constructed — NOT run)

```sh
kompile fvk/mti_parent_links.k --backend haskell        # compile the fragment
kast    --backend haskell fvk/mti_parent_links-spec.k   # (optional) parse check
kprove  fvk/mti_parent_links-spec.k                     # expected: #Top
```

**Expected outcome, reasoned (not executed):**

- `(FOLD)`, PO-1..PO-6, PO-9, PO-10, PO-12, PO-13: bounded / linear / definitional
  ⇒ `kprove` is expected to return `#Top`.
- `(SELECT-PL)` PO-7/PO-8 and `(KEY-INDEP)` PO-11/PO-14: the goals reduce to
  facts about `anyPL`/`candOf`/`lastF`/membership on a **symbolic** list. The
  bundled tier (linear Z3 + map-extensionality `[simplification]`) does not close
  list-induction automatically, so a bare `kprove` would leave these as residual
  obligations. They are **[ESCALATION BOUNDARY]**: discharged **by hand** above
  (§3–§4); machine closure needs list-induction `[simplification]` lemmas for the
  three abstraction functions (route via `knowledge/sources.md`: reachability +
  μ-logic/inductive predicates). **Not** admitted as `[trusted]`.

This is the same honest posture as the kit's insertion-sort example: every claim
is stated and hand-proved; only the inductive *machine* check is deferred and
named, never faked.

## 6. Residual risk

- **Partial vs. total correctness.** The default is partial correctness. Here the
  loop is a `for` over a *finite* `local_fields` list (no unbounded recursion), so
  termination is immediate; total correctness adds nothing of interest. Noted, not
  separately discharged.
- **Trusted base.** (a) **Fragment adequacy** — `mti_parent_links.k` models the
  *post-filter* visit sequence; the three Python filters are assumed faithfully
  reflected in `VS` (Findings F-5/F-6). (b) the reachability proof-system
  metatheory + `kprove`. (c) the SMT / `[simplification]` oracle for the [Z3]
  VCs. (d) the **[ESC]** list-induction VCs are hand-checked, not machine-checked.
- **"Constructed, not machine-checked."** Upgrading to *machine-verified* requires
  running §5 (and adding the list-induction lemmas) to obtain `#Top`.

## 7. Benefit payoffs

- **Benefit 2 (hidden bugs).** The formalization isolated the exact reason order
  mattered (unconditional last-write-wins) and the exact property that fixes it
  (the **biconditional** I2, with the contrapositive step in §3 PO-8 the subtle
  part), and confirmed both issue symptoms share one root cause (F-8). It also
  surfaced two pre-existing, out-of-scope edge cases (F-6, F-7) without
  conflating them with the fix.
- **Benefit 1 (test redundancy).** See §8. Conditioned on machine-checking.

## 8. Test-redundancy recommendation (recommendation-only; conditioned on `kprove` = `#Top`)

> The kit never deletes tests, and the task forbids modifying test files. The
> following is advisory only.

Once `(SELECT-PL)`+`(KEY-INDEP)` are machine-checked, these in-domain
input/output checks are **subsumed** by the proof (each is one point of a property
proved for *all* orders):

- **Redundant (subsumed):** any test asserting that, given an explicit
  `parent_link=True` OTO plus another OTO to the same parent, the explicit one is
  chosen — for a *particular* declaration order. The proof covers *every* order
  (I2 + corollary). Two such order-specific point tests collapse to the one
  theorem. *Reason:* `parent_link=True` candidate present ⇒ chosen is it,
  ∀ order.

**Keep (NOT subsumed):**

- `invalid_models_tests…test_missing_parent_link` — pins behaviour on the
  *no-parent-link* domain (I3 + `_prepare` raising). This is exactly an
  out-of-contract boundary the fix must not regress; **keep**.
- `model_inheritance…test_abstract_parent_link` and the `ParkingLot(Place)`
  model test — exercise the abstract-base propagation / FK-coexistence wiring
  (integration of this loop with the mro/abstract branch), beyond the unit
  contract; **keep**.
- Any migration / `_set_pk_val` runtime tests (F-8) — integration, not unit
  contract; **keep**.

CI time saved is marginal here (a couple of micro model-definition tests); the
real deliverable of this audit is **Benefit 2** — the confirmation, with named
obligations, that V1 is correct and complete for the issue.
