# PROOF.md — constructed correctness proof (django__django-15268)

**CONSTRUCTED, NOT MACHINE-CHECKED.** This write-up constructs the proof by symbolic
execution against [`optimizer.k`](optimizer.k) and emits the exact `kompile`/`kprove`
commands (§7) to machine-check it later. Claims live in
[`optimizer-spec.k`](optimizer-spec.k); obligations in
[`PROOF_OBLIGATIONS.md`](PROOF_OBLIGATIONS.md).

---

## 1. What is proved (plain language)

1. For every pair of `AlterFooTogether` operations, `reduce` returns the right verdict:
   **collapse** when same kind + same model, **commute (`True`)** when same model +
   different kind (← the fix) or different model, **barrier (`False`)** when the other op
   is not an `AlterFooTogether` on the same model. (REDUCE-\*)
2. The **commute** verdict is sound: two ops on distinct `(kind, model)` slots apply in
   either order to the same state. (COMMUTE)
3. The optimizer's fixpoint loop **terminates**. (OPT-TERM)

Together these establish the worked goal: the interleaved 4-op list from the issue
optimizes to the 2-op list, with the reorders it performs being semantics-preserving.

## 2. Proof of the `reduce` contract (REDUCE-\*)

`reduce` is straight-line (no loop), so the proof is pure symbolic execution +
case analysis on the three input booleans `SM, SS, BT`. Driving the `#if` cascade in
`optimizer-spec.k` (each `===`/`and`/`not` is a builtin `Bool` step):

- **REDUCE-COLLAPSE** `reduce(true,true,true,op(K,M,V))`:
  guard `BT ∧ SS ∧ SM = true` ⇒ first branch ⇒ `collapse(op(K,M,V))`. Matches the real
  `ModelOptionOperation.reduce` returning `[operation]`. `=> collapse(op(K,M,V))`, `#Top`.
- **REDUCE-COMMUTE-DIFFMODEL** `reduce(false,_,true,_)`:
  first guard false (`SM=false`); second guard `¬SM = true` ⇒ `commute`. Matches
  `ModelOperation.reduce` → `not references_model = True`. `#Top`.
- **REDUCE-COMMUTE-SAMEMODEL** (***the fix***) `reduce(true,false,true,_)`:
  first guard false (`SS=false`); second guard false (`¬SM=false`); third guard
  `BT ∧ SM = true ∧ true = true` ⇒ `commute`. This is exactly the V1 `or`-clause firing
  after `super().reduce()` returned `False`. `#Top`.
- **REDUCE-SCOPE** `reduce(true,_,false,_)`:
  first guard false (`BT=false`); second false (`¬SM=false`); third false (`BT=false`)
  ⇒ `barrier`. Matches V0 — the fix's clause is gated out by `isinstance(...)=False`.
  `#Top`.

All four reduce to `#Top` by Boolean simplification (Z3 tier). No nonlinear VC.

> **Adversarial cross-check (benefit 2).** The only row whose value differs from V0 is
> REDUCE-COMMUTE-SAMEMODEL (`False → True`). Every other row is bit-identical to V0,
> proving the change is *surgical*: it cannot alter collapse, different-model, or
> non-together behaviour. This is what PO-DIFFMODEL, PO-COLLAPSE, PO-SCOPE assert.

## 3. Proof of COMMUTE (soundness of the `True` verdict)

Goal: `apply(op(U,M,VU)) apply(op(I,M,VI))` and the swapped order reach the same
`<model>`. Symbolic execution of the single `apply` rule (twice):

```
<model> MS </model>
  -- apply(op(U,M,VU)) -->  <model> MS[slot(U,M)<-VU] </model>
  -- apply(op(I,M,VI)) -->  <model> MS[slot(U,M)<-VU][slot(I,M)<-VI] </model>
```
swapped:
```
<model> MS </model>
  -- apply(op(I,M,VI)) -->  <model> MS[slot(I,M)<-VI] </model>
  -- apply(op(U,M,VU)) -->  <model> MS[slot(I,M)<-VI][slot(U,M)<-VU] </model>
```
**VC-DISJOINT** (the one nontrivial VC): `MS[slot(U,M)<-VU][slot(I,M)<-VI] #Equals
MS[slot(I,M)<-VI][slot(U,M)<-VU]`. Discharged by the map-commutativity
`[simplification]` lemma — updates on **distinct keys** commute — with the side fact
`slot(U,M) =/=K slot(I,M)` (true because `U =/=K I`: distinct constructors). This is the
matching-logic image of the real `alter_model_options` merging the **single** key
`unique_together` vs `index_together` (`state.py:170`). `#Top`.

The `<out>` effect log differs only in *order* (`eff(U…) eff(I…)` vs `eff(I…) eff(U…)`);
since the two effects target disjoint database objects, the multiset — hence the net DB
result — is identical. (Recorded as a multiset-equality observation; it is not needed for
the state goal.)

## 4. Proof of OPT-TERM (loop termination)

`optimize` is `while result != operations: operations = optimize_inner(operations)`.
Abstract the state by the variant `R` = number of reductions still available
(≤ list length, ≥ 0). The claim is the down-counting circularity (shape of
`examples/03-sum-down`):

```
<k> while (0 < r) : (r = r - 1 ;) => skip ... </k>
<store> r |-> (R => 0) </store>   requires R >=Int 0   [all-path]
```

Proof by guarded coinduction:
- Evaluate the guard `0 < R` — the genuine `=>⁺` step that earns the circularity.
- **Case `R > 0`** (`#Or` split): run the body `r = r - 1` (now `r |-> R-1`), then invoke
  the circularity on the shifted state `R-1`, whose precondition `R-1 >=Int 0` follows
  from `R > 0` (Z3). Reaches `r |-> 0`. ✓
- **Case `R ≤ 0`**, i.e. `R = 0` under `R ≥ 0`: guard false ⇒ `skip` ⇒ `r |-> 0`. ✓

Variant `R` is bounded below (`≥ 0`) and strictly decreases each pass ⇒ termination.
The fix adds only `True` verdicts, which never increase the list length, so the real `R`
still decreases on every changing pass — termination is preserved. VC `R>0 ⇒ R-1 ≥ 0`:
Z3. `#Top`.

## 5. OPT-SOUND — discharged per step, full induction escalated

Each optimizer rewrite is one of:
- **collapse** — replaces `a` (and a later same-kind+model `b`) by `[b]`; sound because
  `a`'s entire effect on `slot(kind,model)` is overwritten by `b` before any reader (the
  optimizer only collapses when nothing in between references that option — guaranteed by
  the in-between verdicts). = PO-COLLAPSE.
- **commute-reorder** — moves `a` across in-between ops; the optimizer's guards permit
  this only when every in-between verdict is `True` (right branch: `right` stays True;
  left branch: `all(op.reduce(other) is True …)`), i.e. only across ops that COMMUTE with
  `a`. = PO-COMMUTE.

So no individual optimizer step changes net semantics. The **whole-program** statement
("for *all* input lists, `optimize` preserves net semantics") needs structural induction
over the list together with a faithful model of `ProjectState` and `SchemaEditor` —
recursive-data + relational reasoning outside the bundled tier.

> `[ESCALATION BOUNDARY]` — PO-OPT-SOUND (whole-list). Route: reachability-logic
> induction over lists + a state/heap model (FM 2012 / LICS 2013; multiset reasoning per
> `knowledge/sources.md`). **Not** admitted as `[trusted]`. This is a proof-capability
> limit, not evidence of a code defect: the step-local obligations the fix actually
> depends on (PO-COLLAPSE, PO-COMMUTE, PO-TERM) are all discharged.

## 6. Test-redundancy (benefit 1) — conditioned on machine-checking

The relevant tests live in `tests/migrations/test_optimizer.py` (read-only here).

- **KEEP — `test_alter_alter_unique_model`, `test_alter_alter_index_model`,
  `test_alter_alter_table_model`, `test_alter_alter_owrt_model`.** These pin the
  same-kind collapse (PO-COLLAPSE), a *different* code path from the fix. The proof of the
  fix does not subsume them (it relies on them being preserved). Keep.
- **KEEP — any new interleaved `AlterUnique/IndexTogether` optimization test (the issue's
  scenario).** This is an *integration* check over the full `optimize` loop. Because
  PO-OPT-SOUND's whole-list statement is escalated (not machine-checked), this test is
  **not** subsumed and must be **kept** as the executable witness of the end-to-end
  behaviour. (This is precisely the kind of test the kit says to keep when verification
  stops at an escalation boundary.)
- **No removals recommended.** Nothing here is subsumed by a *machine-checked* proof
  (there is none yet), and the genuinely end-to-end test is out of the verified unit's
  domain. Honesty gate honoured.

## 7. Reproduce the machine check

```sh
kompile optimizer.k --backend haskell        # compile the mini-Python fragment
kast    --backend haskell optimizer-spec.k   # (optional) confirm the claims parse
kprove  optimizer-spec.k                      # discharge REDUCE-*, COMMUTE, OPT-TERM
                                              # expected: #Top for each claim
```

Until `kprove` returns `#Top`, every result above is **constructed, not
machine-checked**, and no test should be deleted.

## 8. Residual risk

- **Partial correctness.** OPT-TERM gives termination; OPT-SOUND is partial (whole-list
  equivalence escalated). The fix's *local* soundness (PO-COMMUTE/COLLAPSE) is complete.
- **Abstraction gap.** `optimizer.k` abstracts operations to `(kind,model,value)` and
  state to a key→value map; faithful to `state.py:170` and the two `database_forwards`
  paths, but it is a fragment, not real Django.
- **Trusted base.** K reachability metatheory + `kprove`; the SMT/`[simplification]`
  oracle (VC-DISJOINT, map-extensionality); the "constructed, not machine-checked" caveat.
