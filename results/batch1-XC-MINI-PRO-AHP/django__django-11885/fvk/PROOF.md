# PROOF.md — constructed correctness proof for `django__django-11885` V1

**CONSTRUCTED, NOT MACHINE-CHECKED.** This write-up constructs the proof by
symbolic execution against `fvk/mini-deletion.k`, discharges the loop circularity
by guarded coinduction, and discharges the arithmetic/set VCs. It does **not** run
`kompile`/`kprove` (no execution environment; MVP scope). The commands to
machine-check it later are in §J. Artifacts: `fvk/mini-deletion.k`,
`fvk/mini-deletion-spec.k`. Obligation IDs refer to `fvk/PROOF_OBLIGATIONS.md`.

The proof has two layers: the **K layer** (the OR-fold computes the union of field
row sets — `(FOLD)`+`(COMBINE)`) and the **set-algebra layer** (V0 ≡ V1 deleted
set/count, ordering, batching) discharged as first-order VCs over the same `rows`
/ `bigU` vocabulary.

---

## §A — The one algebra fact: `rows(p or q) = rows(p) ∪ rows(q)`

A fast-delete query targets a **single table** and filters **direct FK columns**
(`f_k_id IN (…)`), so it has no joins. On one table, the rows matched by a WHERE
that is a disjunction are the union of the rows matched by each disjunct:
`|σ_{P∨Q}(t)| = |σ_P(t)| ∪ |σ_Q(t)|`. This is the `rows` homomorphism, encoded as
the `[simplification]` rule `rows(P1 or P2) => rows(P1) U rows(P2)` with
`rows(atom(K)) => S(K)`. (Faithfulness of this abstraction to the live SQL
compiler is EB-1, named in PROOF_OBLIGATIONS.) `∪` is ACUI (assoc/comm/unit/idem)
— the four `[simplification]` facts in the spec module.

---

## §B — `(FOLD)` loop circularity (discharges the heart; PO-ROWSET core)

**Claim.** From `acc = A, i = I, n = N` with `1 ≤ I ≤ N`,
`while i<n { acc = acc or atom(i); i = i+1 }` reaches `i = N` with
`rows(acc) = rows(A) U bigU(I,N)`.

**Guarded-coinduction proof.** K registers `(FOLD)` as its own hypothesis,
usable only after ≥1 genuine `=>⁺` step (guardedness).

1. **Guard step (earns the hypothesis).** `while i<n {body}` desugars (Axiom) to
   `if i<n {body; while…} else {skip}`. `strict(1)` heats `i<n`: `i↦I`, `n↦N`,
   then `I <Int N` fires. This is the genuine `=>⁺`.
2. **Case-split on `I <Int N` (Case Analysis, `#Or`):**

   - **Body-taken (`I < N`, i.e. `I ≤ N-1`).** `if true` ⇒ run `body`:
     - `acc = acc or atom(i)`: heat RHS (seqstrict) — `acc ↦ A`, `atom(i)` heats
       `i ↦ I` giving `atom(I)`; result value `A or atom(I)` (a `Pred` KResult,
       no further rule). Store: `acc ↦ A or atom(I)`.
     - `i = i + 1`: `I +Int 1`. Store: `i ↦ I+1`.
     - Reach `while i<n {body}` with `acc = A or atom(I), i = I+1`. Its
       precondition `1 ≤ I+1 ≤ N` holds (`I ≥ 1 ⇒ I+1 ≥ 2 ≥ 1`; `I ≤ N-1 ⇒
       I+1 ≤ N`). **Invoke `(FOLD)`** (coinductive hypothesis, legal after step 1)
       at `{A := A or atom(I), I := I+1}`: it yields
       `rows(acc_final) = rows(A or atom(I)) U bigU(I+1, N)`.
     - **VC-B (Consequence).** Must equal the claimed
       `rows(A) U bigU(I,N)`:
       ```
       rows(A or atom(I)) U bigU(I+1,N)
         = (rows(A) U S(I)) U bigU(I+1,N)        [rows homom., rows(atom(I))=S(I)]
         = rows(A) U (S(I) U bigU(I+1,N))        [assoc/comm of U]
         = rows(A) U bigU(I,N)                   [peel-left: bigU(I,N)=S(I) U bigU(I+1,N), I<N]
       ```
       Discharged by the peel-left `[simplification]` rule (its `requires A<Int B`
       holds: `I < N`). ✓

   - **Exit (`¬(I<N)`, with `I ≤ N` ⇒ `I = N`).** `if false` ⇒ `skip` ⇒ `.K`;
     `acc` unchanged `= A`, `i = N`. **VC-X:**
     `rows(A) = rows(A) U bigU(N,N) = rows(A) U noRows = rows(A)` since
     `bigU(N,N)=noRows` (`A≥B` rule, `N≥N`) and `R U noRows = R`. ✓

Both branches land on `rows(acc) = rows(A) U bigU(I,N)`. `(FOLD)` is proved
(partial correctness; termination §K). ∎

---

## §C — `(COMBINE)` function contract (PO-ROWSET, PO-COUNT)

**Claim.** `acc=atom(0); i=1; while…; return acc` with `N≥1` reaches
`out = R` with `rows(R) = bigU(0,N)`.

**Proof (Transitivity).**
1. `acc = atom(0)`: store `acc ↦ atom(0)` (a `Pred` KResult).
2. `i = 1`: store `i ↦ 1`.
3. Entry to the loop: `acc = atom(0), i = 1, n = N`. Precondition of `(FOLD)`:
   `1 ≤ 1 ≤ N` ⇐ `N ≥ 1` (the function precondition). **Use `(FOLD)` as a lemma**
   at `{A := atom(0), I := 1}`:
   `rows(acc) = rows(atom(0)) U bigU(1,N) = S(0) U bigU(1,N)`.
4. **VC-C (Consequence):** `S(0) U bigU(1,N) = bigU(0,N)` by peel-left at `A=0`
   (`0<N` ⇐ `N≥1`). ✓
5. `return acc`: `out ↦ acc`, so `rows(R) = bigU(0,N)`. ∎

**Interpretation (PO-ROWSET).** With fields `f_0..f_{m-1}` and `N=m`,
`rows(result) = S_0 ∪ … ∪ S_{m-1}` — exactly the union V1 deletes for the table.

**PO-COUNT.** V1 reports `|rows(result)| = |⋃_k S_k|`. V0 reports
`Σ_{k=0}^{m-1} |S_k \ (S_0∪…∪S_{k-1})|`, a disjoint decomposition of `⋃_k S_k`,
hence `= |⋃_k S_k|`. Equal. (Finite inclusion–exclusion; Z3-tier once the
set-difference cardinalities are introduced as the telescoping partition.) ∎

---

## §D — PO-FEWER (the optimization is real)

Per table, with `b_1 = bulk_batch_size([1 field], O)`,
`b_m = bulk_batch_size([m fields], O)`:
`#V0 = m · ceil(|O|/b_1)`, `#V1 = ceil(|O|/b_m)`.
- Uncapped backend: `b_1=b_m=|O|` ⇒ `#V0=m`, `#V1=1`. m-fold fewer.
- SQLite: `b_1=500`, `b_m=999//m`. For `|O|≤500·… `, e.g. `m=2,|O|=1000`:
  `#V0=2·2=4`, `#V1=ceil(1000/499)=3`. Always `#V1 ≤ #V0` because
  `ceil(|O|/(999//m)) ≤ m·ceil(|O|/500)` for `m≥1` (the per-field 500 cap is
  looser only by the single-field special case; the combined budget `999//m` per
  field × m fields ≈ 999 ≥ 500). Z3-tier monotonicity VC. ✓

---

## §E — PO-DECISION (classification unchanged)

`can_fast_delete` is a pure function of `(model(x), f)`. For a queryset
`q = related_objects(related, batch)`, `model(q) = q.model = related.related_model`
(V0). For the class `c = related.related_model`, `model(c) = c._meta.model = c`
(V1, §SPEC.3). `related.related_model is related.related_model` ⇒ same `model`,
same `f` ⇒ identical boolean. No row of the queryset is ever inspected by
`can_fast_delete`, so dropping the queryset construction changes nothing. ∎

---

## §F — PO-ORDER (reordering soundness)

Let `FD` be the set of fast-deletable tables in one `delete()`. For `t ∈ FD`,
`can_fast_delete(t)` requires every `related ∈ get_candidate_relations_to_delete(t)`
to be `DO_NOTHING`. Hence there is **no** CASCADE/SET edge `t' → t` with `t,t'∈FD`
(such an edge would be a non-`DO_NOTHING` relation into `t`, contradicting
`t∈FD`). So the sub-graph of `FD` under delete-ordering edges is **edgeless**:
deletions of distinct `t,t'∈FD` commute. All fast deletes also run strictly before
all regular (`self.data`) deletes within a single `transaction.atomic`. Therefore
the final database state is independent of the order/grouping of `self.fast_deletes`.
∎ (This is also why merging two entries for the same `t` — `S_a` then `S_b` vs
`S_a ∪ S_b` — yields the same rows: §A/§C.)

---

## §G — PO-BATCH (parameter budget)

`get_del_batches(O, fields)` returns slices of size `≤ c := max(bulk_batch_size(
[m names], O), 1)`. A combined query over a slice has `m·c` parameters.
- Capped (`L := max_query_params` finite): `bulk_batch_size = L // m`, so if
  `m ≤ L` then `c = max(L//m, 1) = L//m ≥ 1` and `m·c = m·(L//m) ≤ L`. ✓
  (Z3: `m·(L div m) ≤ L`.) The clamp `max(…,1)` only changes `c` when `L//m = 0`,
  i.e. `m > L` — flagged as the unreachable-in-practice edge (F3).
- Uncapped (`L = None`): `bulk_batch_size = |O|`, the backend's declared safe size;
  ASSUMED-BACKEND (F3). The single batch carries `m·|O|` params — V0 carried `|O|`
  per field; the backend's contract ("send everything") is the same one V0 used.

---

## §H — PO-LAZY / PO-DIRECT

The fast path appends `sub_objs` with **no** truthiness test (matching V0's fast
branch), so the queryset is never evaluated during collection. At delete time,
`_raw_delete → delete_qs`: since every disjunct filters a direct FK column,
`innerq.alias_map` contains only the base table, so
`innerq_used_tables == tuple(self.alias_map)` and `delete_qs` sets
`self.where = innerq.where` — a single `DELETE FROM t WHERE … OR …`, no subquery.
∎ (The compiler step that makes `fk__in` join-free is EB-1.)

---

## §I — PO-IMPORT

`deletion.py` is imported at line 7 of `django/db/models/__init__.py`. The new
`from django.db.models import query_utils, signals, sql` resolves `query_utils` as
a **submodule import**, independent of `__init__`'s later attribute binding;
`query_utils` imports only `copy/functools/inspect`, `…constants.LOOKUP_SEP`,
`django.utils.tree` — none import `deletion`. No cycle. `functools.reduce` and
`operator.or_` are stdlib. ∎

---

## §J — Machine-check commands (constructed, not yet run)

```sh
kompile fvk/mini-deletion.k --backend haskell          # compile the fragment semantics
kast    --backend haskell fvk/mini-deletion-spec.k     # (optional) confirm the claims parse
kprove  fvk/mini-deletion-spec.k                        # discharge (FOLD) and (COMBINE); expect: #Top
```
A `#Top` from `kprove` upgrades §B–§C from *constructed* to *machine-verified*.
The set-algebra VCs (§C count, §D, §G) are linear/finite and Z3-dischargeable; the
`rows`/`bigU` `[simplification]` lemmas in the spec module are the oracle for the
`∪` facts.

---

## §K — Residual risk (honesty gate)

- **Partial correctness.** §B is partial: *if* the fold terminates,
  `rows = bigU`. Termination is obvious here (the measure `N − i` strictly
  decreases, bounded below by 0) but is **not** part of the default proof; flagged
  as a recommendation. The real `reduce` over a finite `related_fields` list
  trivially terminates.
- **Trusted base.** (i) the `rows` homomorphism's faithfulness to the SQL
  compiler (EB-1); (ii) the mini-X fragment's adequacy for the fold; (iii) the
  reachability metatheory + `kprove` + the Z3/`[simplification]` oracle;
  (iv) backend parameter ceilings (EB-2, ASSUMED-BACKEND).
- **Constructed, not machine-checked** — the §J commands are not run here.

---

## §L — The two benefit payoffs (per the kit)

- **Benefit 2 (bugs/edges surfaced):** F3 (the `m × batch` parameter multiplier on
  uncapped backends) and F4 (`reduce` non-empty precondition) are real, subtle
  facts the spec flushed out; both are precisely bounded and shown safe on the
  intended domain. No latent crash on any reachable in-tree input.
- **Benefit 1 (test redundancy):** see §M.

---

## §M — Test-redundancy (recommendation only; conditioned on machine-checking)

Once `(COMBINE)`/`(FOLD)` are machine-checked (`kprove ⇒ #Top`) **and** EB-1 is
accepted, a unit test that merely asserts *"`p.delete()` deletes exactly these rows
/ returns this count"* for a fixed small schema with multiple same-table FKs is
**subsumed** by PO-ROWSET+PO-COUNT (the contract holds for all such schemas).
**Keep**, explicitly:
- `assertNumQueries(...)` tests — they pin PO-FEWER, the optimization itself, and
  are the regression guard for it (and are backend-sensitive, §D/§G).
- any test exercising **uncapped-backend large deletions** — out-of-budget domain
  for PO-BATCH (F3), exactly where behavior is ASSUMED-BACKEND.
- integration/transaction-ordering tests (PO-ORDER is the unit fact, not the
  end-to-end wiring).
**Recommendation only — never auto-delete; run §J first.** (The benchmark test
suite is fixed and hidden here, so this is advisory and nothing is removed.)
