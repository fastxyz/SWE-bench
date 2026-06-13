# PROOF.md — django-16263 (constructed, NOT machine-checked)

Constructs the correctness proof of `fvk/SPEC.md` against a **mini-ORM** K
fragment, discharges the `PROOF_OBLIGATIONS.md` VCs, marks escalation
boundaries, and emits the `kompile`/`kprove` commands. Per the MVP honesty gate
(`fvk_materials/commands/verify.md`), **nothing here was run through
`kprove`**; results are *constructed*.

The target is graph/SQL-shaped, outside the fast-path sweet spot, so we follow
the "escalation done right" discipline: a faithful minimal model, all claims
stated, every VC the bundled tier *can* discharge discharged, the rest marked
`[ESCALATION BOUNDARY]`.

---

## 1. Mini-ORM semantics — `mini-orm.k`

Models only what determines `count()`/`exists()`: base rows, active joins with
multiplicities, a GROUP BY mode, the selected annotations, the referenced set,
and the two state-transformers under audit (`strip`, `drop_groupby`). Annotation
*values* are deliberately absent — they never affect row count.

```k
module MINI-ORM-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  syntax GroupMode ::= "NONE" | "BYPK" | "BYTUPLE"
  syntax AnnInfo   ::= ann(isAgg: Bool, cols: Set)         // cols: table aliases read
  syntax Stmt      ::= "strip"   "(" Id ")"                // strip annotation alias
                     | "dropGB"                            // exists(): drop GROUP BY
  syntax KResult   ::= Int | Bool
endmodule

module MINI-ORM
  imports MINI-ORM-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports SET

  configuration
    <k>      $PGM:Stmt        </k>
    <base>   $B:Int           </base>   // base-table row count, symbolic, B >= 0
    <joins>  $J:Map           </joins>  // alias |-> Mult(Int>=1); base alias |-> 1
    <refcnt> $R:Map           </refcnt> // alias |-> Int
    <gb>     $G:GroupMode      </gb>
    <ann>    $A:Map            </ann>   // annAlias |-> AnnInfo
    <ref>    $Ref:Set          </ref>   // referenced annotation aliases

  // ---- rowcount: the meaning of count() (a spec-level [function]) ----
  // ungrouped: base rows times the product of multiplicities of active joins
  // grouped by pk: exactly B groups; grouped by tuple: a function of kept joins
  syntax Int ::= rowcount(GroupMode, Int, Map) [function]
  rule rowcount(BYPK,    B, _) => B
  rule rowcount(NONE,    B, J) => B *Int prodMult(J)
  // BYTUPLE left abstract (a function of J only); not needed by the proofs below
  syntax Int ::= prodMult(Map) [function]            // Π of join multiplicities
  rule prodMult(.Map) => 1
  rule prodMult((_:KItem |-> M:Int) Rest:Map) => M *Int prodMult(Rest)
    requires M >=Int 1

  // ---- strip(a): remove annotation a and the joins only it uses ----
  // Precondition enforced by the caller's gate: strippable(a) holds and
  //   a not in Ref.  (See _annotation_is_strippable / unused-set.)
  rule <k> strip(A:Id) => .K ... </k>
       <ann>    ... A |-> ANN => .Map ... </ann>
       <joins>  J  => removeOwnedJoins(ANN, J, R) </joins>
       <refcnt> R  => unrefOwned(ANN, R)          </refcnt>
    requires strippable(ANN) ==K true

  // base-only annotation owns no join => J, R unchanged
  // aggregate annotation: its joins are removed; GROUP BY (already set) absorbs it
  syntax Map ::= removeOwnedJoins(AnnInfo, Map, Map) [function]
  syntax Map ::= unrefOwned(AnnInfo, Map)            [function]
  // (defined extensionally in the proof; key facts used are the two lemmas L1/L2)

  // ---- dropGB: exists() drops a GROUP BY that no HAVING needs ----
  rule <k> dropGB => .K ... </k> <gb> BYPK => NONE </gb>

  // ---- the safety predicate, mirrored from _annotation_is_strippable ----
  syntax Bool ::= strippable(AnnInfo) [function]
  rule strippable(ann(true,  _))  => true                       // aggregate
  rule strippable(ann(false, C)) => onlyBase(C)                 // base-only
  syntax Bool ::= onlyBase(Set) [function]                      // C ⊆ {base}
endmodule
```

## 2. Claims — `mini-orm-spec.k`

```k
requires "mini-orm.k"
module MINI-ORM-SPEC
  imports MINI-ORM
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // (STRIP-COUNT) stripping a strippable, unreferenced annotation preserves rowcount.
  claim <k> strip(A:Id) => .K </k>
        <base> B:Int </base> <joins> J:Map </joins> <refcnt> R:Map </refcnt>
        <gb> G:GroupMode </gb> <ann> A |-> ANN:AnnInfo REST:Map </ann> <ref> RF:Set </ref>
    requires (strippable(ANN) ==K true)
     andBool (notBool (A in_keys(toKeysSet(RF))))          // a ∉ Ref
     andBool gbConsistent(G, A |-> ANN REST)               // agg ⇒ G≠NONE  (annotate invariant)
    ensures  rowcount(G, B, J) ==Int rowcount(?G':GroupMode, B, ?J':Map)
    [all-path]
    // ?G',?J' are the post-state <gb>/<joins>; the proof shows the two rowcounts coincide.

  // (DROP-GB) exists(): dropping a HAVING-free GROUP BY preserves "row exists".
  claim <k> dropGB => .K </k> <base> B:Int </base> <joins> J:Map </joins> <gb> BYPK => NONE </gb>
    requires B >=Int 0 andBool allLeftJoins(J)
    ensures  (rowcount(BYPK, B, J) >Int 0) ==Bool (rowcount(NONE, B, J) >Int 0)
    [all-path]

  // (CLOSURE) the transitive-reference worklist loop terminates at the least fixed point.
  //   stated over symbolic (R,W); measure |annotations| - |seen| strictly decreases.
  //   (worklist modelled in the loop semantics; see §4.6)
endmodule
```

Two `[simplification]` lemmas the arithmetic needs (the "VC oracle"):

```k
// L1 (base-only): a base-only annotation owns no join — removeOwnedJoins is identity.
rule removeOwnedJoins(ann(false, C), J, _) => J requires onlyBase(C) ==K true [simplification]
// L2 (aggregate under grouping): with G ∈ {BYPK,BYTUPLE}, rowcount ignores J.
rule rowcount(BYPK, B, _J) => B [simplification]
```

## 3. Proof strategy

Each VC is symbolic execution of one `strip`/`dropGB` step followed by a
Consequence (arithmetic) discharge. There is exactly one genuine loop (the
closure, PO6); its circularity is discharged by guarded coinduction with the
`seen` measure. The pieces compose by Transitivity into the
`get_count`/`exists` contracts.

## 4. Discharge

### 4.1 PO1a — aggregate branch (STRIP-COUNT, `isAgg = true`)
One `strip(A)` step fires (`strippable(ann(true,_)) = true`). Two reachable
post-shapes, both discharged by **L2**:
- All aggregates gone, no kept annotation → `get_count` reaches
  `get_aggregation`'s else-branch: `G` flag set but SELECT emptied → compiler
  emits no GROUP BY → post `rowcount(NONE, B, J')` with `J'` = `J` minus the
  aggregate's now-orphan joins. Pre value `rowcount(BYPK, B, J) = B` (L2). Post
  value: with all multiplying joins removed and no grouping, `prodMult(J') = 1`
  ⇒ `B *Int 1 = B`. VC `B ==Int B` → Z3 `#Top`. **Equal.**
- A kept annotation forces the subquery path with grouping retained
  (`BYPK`/`BYTUPLE`): both pre and post are `rowcount(BYPK,B,·)=B` by L2,
  independent of `J` ⇒ VC `B ==Int B`. **Equal.**

*Soundness of L2 (the modelling fact):* `GROUP BY <base pk>` yields exactly one
row per base row regardless of how many times joins multiplied that row — the
SQL fact the base commit already relied on for `annotate(Count(...)).count()`.

### 4.2 PO1b — base-only branch (STRIP-COUNT, `isAgg = false ∧ onlyBase`)
`strip(A)` fires; **L1** rewrites `removeOwnedJoins(ann(false,C),J,_) ⇒ J` and
`unrefOwned` leaves `R` unchanged (no non-base alias on any column, so
`_unref_annotation_joins`' `while` never enters). `G` untouched. Post state has
identical `<joins>` and `<gb>` ⇒ `rowcount(G,B,J) ==Int rowcount(G,B,J)` →
reflexive VC → `#Top`. **Equal.**

### 4.3 PO3 — UNREF-EXACT (`_unref_annotation_joins`)
Not an arithmetic VC but a structural lemma about `refcnt`. Proof by the
one-ref-per-column-path accounting (PROOF_OBLIGATIONS PO3): each `Col` of the
annotation contributes exactly one ref to each alias on its parent-chain;
walking that chain unrefs each once; summed over `_gen_cols` it is exact, and a
join hits 0 iff unshared. The walk is guarded by `alias in self.alias_refcount`
and stops at `base_table`, so it never underflows a shared/base alias. Under the
V2 gate this lemma is only *invoked* for aggregates-with-joins (real walk) and
base-only annotations (empty walk), both covered. **DISCHARGED** (structural,
not SMT).

### 4.4 PO4 — no-regression
By inspection (Consequence with trivial VCs): `get_aggregation` body is the
base-commit text (diff-confirmed); stripping is gated behind `get_count`;
`_strip_unused_annotations` early-returns on `combinator` and on empty `unused`;
`set_annotation_mask` keeps `__count` selected. No state change on these inputs
⇒ reflexive. **DISCHARGED.**

### 4.5 PO5 — DROP-GB (exists)
One `dropGB` step rewrites `<gb> BYPK => NONE`. VC:
`(rowcount(BYPK,B,J) >Int 0) ==Bool (rowcount(NONE,B,J) >Int 0)`, i.e.
`(B > 0) ==Bool (B *Int prodMult(J) > 0)`. Under `allLeftJoins(J)` every
`Mult ≥ 1` ⇒ `prodMult(J) ≥ 1` ⇒ `B*prodMult(J) > 0 ⇔ B > 0`. Linear/zero-factor
fact → Z3 `#Top`. **DISCHARGED.** HAVING case excluded by the guard `not any
referenced aggregate` (then `dropGB` does not fire; original expansion kept).

### 4.6 PO6 — CLOSURE circularity (the one loop)
Model the worklist as `loop(R, W, seen)`. Genuine `=>⁺` step: pop `a` from `W`
(this earns the coinductive hypothesis — guardedness). Case-split on whether
`refs(a)\seen` is empty:
- empty branch → push nothing; `W` shrinks → invoke circularity on `(R, W', seen)`.
- non-empty → for each new `x`: `seen' = seen ∪ {x}` strictly grows → measure
  `|annotations| − |seen|` strictly drops → invoke circularity on the shifted
  state. Exit when `W = ∅`. Both branches reach `(R*, ∅)`. The measure is in ℕ
  and strictly decreases on every push and pops are bounded by pushes ⇒
  **termination**; the fixed point is the least set closed under `refs` ⇒
  **partial correctness**. VCs (`|seen| ≤ |annotations|`,
  `μ ≥ 0`, `μ' < μ`) are linear → Z3. **DISCHARGED (total).**

### 4.7 Compose
`get_count` ≡ clone ∘ add-`Count('*')` ∘ `_strip_unused_annotations({__count}})`
∘ `get_aggregation`. By Transitivity: add-summary doesn't change `rowcount`
(it is a summary, `G` untouched); `_strip_unused_annotations` preserves
`rowcount` by STRIP-COUNT applied to each `unused` alias (each strippable &
unreferenced — PO1) and a no-op otherwise (PO4); `get_aggregation` is the
unchanged base computation of `rowcount`. ⇒ `get_count` returns `rowcount(Q)`
= CONTRACT-COUNT. `exists` ≡ clone ∘ (optional `dropGB`) ∘ rest; DROP-GB (PO5)
preserves "exists". ∎ (constructed)

## 5. Test-redundancy (benefit 1) — recommendation only, conditioned on `kprove`

These existing **count/exists** assertions are *entailed* by the proved
contracts (values shown; the proof makes them hold for the whole input class,
not just the literal point):

| Test (file) | Assertion | Subsumed by |
|---|---|---|
| `aggregation_regress.tests` test_more | `annotate(num_authors=Count("authors")).count() == 6` | PO1a (aggregate strip → `B`) |
| `aggregation_regress.tests` (≈567) | `annotate(has_pk=Q(pk__isnull=False)).count() == 6` | PO1b (base-only strip) |
| `aggregation_regress.tests` (≈1069/1072) | `values(...).annotate(Count(...)).count() == 4 / 6` | PO1a (grouped, `BYTUPLE`/`BYPK`) |
| `aggregation_regress.tests` (≈1160) | `filter(id__in=[]).annotate(Count("friends")).count() == 0` | PO1a + empty WHERE |
| `aggregation.tests` (≈1539) | `annotate(Subquery).annotate(Count("book")).count() == Author.count()` | PO1a + base-only(Subquery) |

**Do NOT remove these.** Honesty gate: the proof is *constructed, not
machine-checked*; and several of them are **out-of-model boundary tests**
(they pin the SQL row semantics the PO7 escalation boundary depends on). They
must be **kept** until `kprove` returns `#Top` *and* PO7's adequacy is
machine-substantiated. Termination/integration tests and all
`aggregate()`/`annotate()` (non-count) tests are kept by default (out of the
count/exists contract).

Recommendation: **keep all existing tests.** Estimated CI saving from removal:
**0s** (correctly — the residual risk in PO7 forbids removal here).

## 6. Residual risk / trusted base

- **Partial vs total:** all VCs except the closure are partial-correctness;
  the closure (PO6) is proved total (trivial measure). The Python statements
  themselves are straight-line (no other loops).
- **`[ESCALATION BOUNDARY]` PO7 — mini-ORM adequacy.** The model equates
  `rowcount` with real SQL `GROUP BY <pk>` (one row/base row), `LEFT JOIN`
  (preserves base rows), to-many fan-out, and `COUNT(*)`-over-subquery. These
  are argued (and cross-checked against the suite's expected counts), **not**
  proved against a SQL-in-K semantics. Route: a real SQL/relational-algebra
  semantics (see `fvk_materials/knowledge/sources.md`). **Not** faked as
  `[trusted]`.
- **F3 assumption — single-clone identity** for filter-embedded annotation
  detection. Holds for `get_count`/`exists`; trusted-base item.
- **Toolchain:** constructed, not machine-checked — run §7.

## 7. Reproduce the machine check (constructed, not run)

```sh
kompile mini-orm.k --backend haskell        # compile the mini-ORM fragment
kast    --backend haskell mini-orm-spec.k   # (optional) parse-check the claims
kprove  mini-orm-spec.k                      # expect: #Top  (STRIP-COUNT, DROP-GB, CLOSURE)
```

`#Top` from `kprove` (plus PO7 adequacy) is what would upgrade these from
*constructed* to *machine-verified* and unlock the (currently withheld)
test-redundancy removals.
