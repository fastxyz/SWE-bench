# PROOF.md — constructed proof for the django-15128 fix

**Status: constructed, NOT machine-checked.** The FVK MVP builds the proof and
emits the `kompile`/`kprove` commands but does not run them. A `#Top` from
`kprove` would upgrade this from *constructed* to *machine-verified*.

Artifacts: [`combine-aliasing.k`](combine-aliasing.k) (mini-X semantics),
[`combine-aliasing-spec.k`](combine-aliasing-spec.k) (claims). Obligations:
[`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md).

---

## 1. What is proved (plain language)

> For every `Query.combine(rhs, connector)` on the verified domain, the
> `change_map` it builds has **disjoint keys and values**. Therefore every
> `change_aliases(change_map)` it triggers — including those reached through a
> queryset subquery embedded in `where` — satisfies
> `assert set(change_map).isdisjoint(change_map.values())`, so `qs1 | qs2`
> (and `&`) never raises the `AssertionError` of django-15128. Additionally the
> original `rhs` is left unmodified and the resulting query is the one combine
> intended to build.

## 2. The two claims (see `combine-aliasing-spec.k`)

- **`(COMBINE)`** — function contract:
  `buildChangeMap`, from `change_map = {}`, over a stream all of whose keys are
  `pref(Pr,_)` and values are in `dom(Ps)`, with `Pr ≠ Ps`, terminates in a map
  `M'` with `disjointKV(M') = true`.
- **`(LOOP)`** — circularity (generalized over the partial map `M` and the
  remaining stream `PS`): preserves the invariant
  `keysPref(M,Pr) ∧ valsDom(M,Ps)` (with `Pr ≠ Ps`) to the end of the stream.

## 3. Proof of `(LOOP)` by guarded coinduction

Coinductive hypothesis: `(LOOP)` itself (every claim in the module is a
circularity). Guardedness: each use is paid for by ≥1 genuine `=>` step (the
loop body firing), never by Reflexivity.

Case-split on `<pairs>` (the loop guard "is the stream empty?"):

**Exit branch `PS = .List`.** The rule
`buildChangeMap => .K  requires <pairs> .List` fires: `<k> => .K`, `<cmap> = M`
unchanged. Postcondition `keysPref(M,Pr) ∧ valsDom(M,Ps)` is exactly the
precondition carried in — discharged by Reflexivity/Consequence. ✓

**Body branch `PS = ListItem(pair(K,V)) REST`.** By the stream precondition
`allKeysPref(PS,Pr) ∧ allValsDom(PS,Ps)`, the head satisfies
`aliasHasPrefix(K,Pr)` and `isValueAlias(V,Ps)`. Two sub-cases (the
`if alias != new_alias` guard):

- `K ≠ V`: the "recorded" rule fires (one genuine `=>` step — *guardedness met*),
  giving `<cmap> = M[K <- V]`. New invariant obligation:
  `keysPref(M[K<-V], Pr)` and `valsDom(M[K<-V], Ps)`. Since
  `keysPref(M,Pr)` held and `aliasHasPrefix(K,Pr)`,
  `keysPref(M[K<-V],Pr)` holds (a key with the right prefix added to a
  right-keyed map); likewise `valsDom` from `isValueAlias(V,Ps)`. Now **invoke
  the circularity** `(LOOP)` on the shifted state
  `⟨<pairs> = REST, <cmap> = M[K<-V]⟩` — its precondition re-checks
  (`keysPref`/`valsDom` just shown; `allKeysPref(REST,Pr) ∧ allValsDom(REST,Ps)`
  inherited; `Pr ≠ Ps` unchanged). The hypothesis closes the goal.
- `K = V`: the "skipped" rule fires (genuine `=>` step), `<cmap> = M`
  unchanged; invariant trivially preserved; invoke `(LOOP)` on
  `⟨REST, M⟩`. ✓

Both branches reach the claimed post-state, so `(LOOP)` holds (partial
correctness; termination separately, PO-TERM).

## 4. Proof of `(COMBINE)` via `(LOOP)` + the core lemma

Instantiate `(LOOP)` at the entry state `M = .Map`, `PS = ` the full stream.
Entry invariant: `keysPref(.Map,Pr) = true`, `valsDom(.Map,Ps) = true`
(both vacuous). `(LOOP)` delivers a final `M'` with
`keysPref(M',Pr) ∧ valsDom(M',Ps)`, `Pr ≠ Ps`. Apply **PO-LEMMA**
(the `[simplification]` rule):
`keysPref(M',Pr) ∧ valsDom(M',Ps) ∧ Pr ≠ Ps ⇒ disjointKV(M') = true`.
That is the postcondition. ∎ (constructed)

## 5. Connecting the model back to the Python code

The claim's three preconditions are the obligations the *real* `combine`
discharges before the loop:

| Model precondition | Python fact | Obligation |
|---|---|---|
| keys all `pref(Pr,_)` | after `rhs.bump_prefix(self, exclude={rhs.base_table})`, every alias in `rhs_tables` is a generated alias | PO-KEYS |
| values all in `dom(Ps)` | `self.join` returns a reused/fresh alias of `self`, whose prefix is `Ps` (or a table name) | PO-VALS |
| `Pr ≠ Ps` | `bump_prefix` picks a prefix strictly after `Ps`; or the no-bump branch already has `rhs.alias_prefix ≠ Ps` | PO-PREFIX |

The postcondition `disjointKV` is precisely
`set(change_map).isdisjoint(change_map.values())` — the assert in
`change_aliases`. The two *other* contracts combine must keep (rhs unmodified,
query equivalent) are PO-NOMUT and PO-EQUIV, discharged by enumeration /
structural argument in `PROOF_OBLIGATIONS.md` (they are not reachability
properties of the loop, so they live as side proofs, not K claims).

## 6. Residual risk & escalation (honesty gate)

- **Constructed, not machine-checked.** Re-run to confirm:
  ```sh
  kompile combine-aliasing.k --backend haskell
  kast    --backend haskell combine-aliasing-spec.k
  kprove  combine-aliasing-spec.k        # expected: #Top
  ```
- **`[ESCALATION BOUNDARY]` — Map-fold induction.** Proving the *whole-map*
  predicates `keysPref`/`valsDom`/`disjointKV` requires structural induction over
  K's `Map` sort. The bundled VC tier (Z3 linear arithmetic + the supplied
  `[simplification]` lemmas) discharges every **per-step** obligation (the single
  `M[K<-V]` extension, the per-pair constructor disequality of PO-LEMMA), which is
  the entire mathematical content. The general fold over an arbitrary symbolic
  `Map` is the same class of obligation as insertion-sort's multiset/`isSorted`
  VCs — it is stated honestly as an escalation boundary and routed to the
  μ-logic / Map-theory sources, **not** admitted as `[trusted]`.
- **Mini-X adequacy.** The model abstracts `self.join`/`reuse`/`table_alias` into
  the input stream's domain facts (PO-KEYS, PO-VALS). Those facts are justified by
  direct inspection of the Python (PROOF_OBLIGATIONS), not assumed away: the
  abstraction is faithful to the alias shapes the real code produces.
- **Partial correctness.** Termination (PO-TERM) is by inspection of the finite
  `for` loop and the bounded prefix search; not encoded as a variant.
- **Trusted base.** K reachability metatheory + `kprove`; Z3; the soundness of
  the `[simplification]` lemmas (the map-extensionality lemma and PO-LEMMA, both
  definedness-preserving).

## 7. Benefit payoffs

- **Benefit 2 (hidden bugs):** writing the spec forced the two subtleties that a
  thinner fix would miss — the **base-table exclusion** (without it the merge
  starting point breaks, F3) and the **`table_map` list aliasing** (without the
  copy the original rhs is corrupted, F6) — and resolved the **name-vs-name
  corner case** by proving rhs has no `name(_)` keys after the bump (F4). All
  three are already handled in V1.
- **Benefit 1 (fewer tests):** see ITERATION_GUIDANCE.md §Test-redundancy
  (recommendation-only, conditioned on running `kprove`).
