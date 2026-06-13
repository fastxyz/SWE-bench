# SPEC.md — formal specification of the django-16263 fix

**Mode:** intent-spec (NL intent ↔ code ↔ formal contract), per
`fvk_materials/commands/formalize.md` §2. **Status:** constructed, not
machine-checked (`fvk_materials` MVP caveat).

## 0. Intent (from `benchmark/PROBLEM.md`)

`QuerySet.count()` (and `exists()`) should ignore annotations that are not
referenced by filters, ordering, grouping, or other annotations, so that e.g.
`Book.objects.annotate(Count('chapters')).count()` runs `SELECT COUNT(*) FROM
book` and returns the same value as `Book.objects.count()`. The optimisation
**must not change the value** that `count()`/`exists()` return.

The governing correctness contract — stronger than the ticket's informal
wording — is Django's documented invariant:

> **(CONTRACT-COUNT)** `qs.count() == len(list(qs))` for every queryset `qs`.
> **(CONTRACT-EXISTS)** `qs.exists() == (len(list(qs)) > 0)`.

Any rewrite of the count/exists query is correct **iff** it preserves the
number of rows `list(qs)` would yield. This is the postcondition every
obligation in `PROOF_OBLIGATIONS.md` is checked against.

## 1. Why a mini-X fragment, and where the escalation boundary is

The code under audit is `django/db/models/sql/query.py` — symbolic
SQL-query construction over graphs of joins, reference-counted table aliases,
annotation expression trees, and a GROUP BY mode. This is far outside the
FVK fast-path sweep (imperative functions over ints/maps; see
`reachability-and-circularities.md` §7). Per the "escalation done right"
discipline, we do **not** model Django's whole compiler. Instead we build a
**mini-ORM** abstraction that keeps exactly the state that determines the row
count, prove the transformation correct against it, and mark the adequacy of
the abstraction (mini-ORM ↔ real Django SQL row semantics) as an explicit
`[ESCALATION BOUNDARY]` (see `PROOF.md` §6).

### 1a. Mini-ORM state (the abstraction)

A count/exists query is abstracted to:

```
Q = (B, J, refcnt, G, Ann, Ref)
  B       : Int   -- number of base-table rows (symbolic, B >= 0)
  J       : Map alias -> Mult     -- active joins (refcnt[alias] > 0); base alias has Mult 1
  refcnt  : Map alias -> Int      -- alias reference counts
  G       : GroupMode = NONE | BYPK | BYTUPLE(cols)   -- grouping
  Ann     : Map ann_alias -> AnnInfo                  -- selected annotations
  Ref     : Set ann_alias         -- annotations referenced by WHERE/HAVING/GROUP BY/ORDER BY/DISTINCT
  AnnInfo = (is_agg : Bool, cols : Set alias)         -- cols = table aliases this annotation reads
  Mult(alias)  : Int, >= 1   -- 1 for to-one / base; may be > 1 (data-dependent) for to-many
```

Row-count semantics (the meaning of `count()`):

```
rowcount(Q) =
    B                                   if G = BYPK
    |distinct G-tuples|                 if G = BYTUPLE(cols)        -- a function of the kept joins only
    B * Π_{alias in reachJoins(J)} fanout(alias)   if G = NONE
```

where `fanout(alias) = Mult(alias)` aggregated along join chains; the key
facts used are only: `fanout(to-one)=1`, `fanout(base)=1`, and a to-many
alias can have `fanout > 1`. Annotation **values** never enter `rowcount`;
annotations affect it **only** through the joins they keep alive and through
forcing `G` (an aggregate annotation forces `G = BYPK` when added via
`annotate()`).

## 2. Function contracts (reachability rules `φ_pre ⇒ φ_post`)

### (GET-COUNT) `Query.get_count`
- **pre:** `true` (any well-formed query state).
- **post:** returns `rowcount(Q)`, i.e. **preserves CONTRACT-COUNT**.
- realised as: `get_count` = clone → add `Count('*')` summary → 
  `_strip_unused_annotations({"__count"})` → `get_aggregation`. Correctness
  reduces to **(STRIP-PRESERVES-COUNT)** below plus the unchanged
  `get_aggregation`.

### (STRIP-PRESERVES-COUNT) `Query._strip_unused_annotations(exclude)`
- **pre:** `exclude` lists the summary aggregates just added (here `{"__count"}`);
  no combinator.
- **post:** for the resulting query `Q'`, `rowcount(Q') = rowcount(Q)`, and the
  selected annotation mask loses exactly the stripped aliases.
- **invariant relied on:** every stripped alias `a` satisfies
  `a ∉ exclude ∧ a ∉ Ref ∧ _annotation_is_strippable(Ann[a])`.

### (STRIPPABLE) `Query._annotation_is_strippable(annotation)` — the **safety predicate** (V2, new)
- returns `true` ⇒ removing `annotation` (and the joins only it uses) leaves
  `rowcount` unchanged. Definition:
  `is_agg(annotation) ∨ cols(annotation) ⊆ {base, ⊥}`
  (aggregate, or introduces no join beyond the base table).
- **soundness (proved in PROOF.md PO1):**
  - `is_agg`: the GROUP BY it forced (`G = BYPK`/`BYTUPLE`) collapses any
    multiplication, and after stripping all aggregates the else-branch yields
    `rowcount = B = ` the grouped value.
  - base-only: removes no join ⇒ `J` unchanged ⇒ `rowcount` unchanged.

### (REF-COMPLETE) `Query._get_referenced_annotation_aliases(extra_exprs)`
- **post:** returns a set `R ⊇ Ref_true`, where `Ref_true` is the set of
  annotations whose removal *could* change the result — i.e. those reachable
  (transitively) from WHERE/HAVING, GROUP BY, ORDER BY, **DISTINCT ON**
  (`distinct_fields`, added in V2), `extra_exprs`, and unselected annotations.
  Over-approximation is sound (keeps more, strips fewer). Misses are unsound.

### (UNREF-EXACT) `Query._unref_annotation_joins(annotation)`
- **post:** decrements `refcnt` by exactly the contribution `annotation` made,
  for each join alias on each of its columns' parent-chains up to (excluding)
  the base. A join drops to `0` (and leaves the FROM clause) **iff** no kept
  clause still references it.

### (EXISTS) `Query.exists(limit)`
- **pre:** `true`.
- **post:** preserves CONTRACT-EXISTS. The V1/V2 change: when `G = True` it
  drops the GROUP BY unless a *referenced aggregate* needs it (a HAVING).
- **soundness:** `rowcount(Q) > 0 ⇔ rowcount(drop_groupby(Q)) > 0` because
  annotation joins are LEFT joins (never delete base rows) and grouping a
  non-empty relation yields a non-empty relation.

## 3. The one loop — circularity

`_get_referenced_annotation_aliases` contains the only loop: the worklist
fixed-point `while to_process: …` computing the transitive closure of
annotation→annotation references.

- **(CLOSURE) loop invariant / circularity:** generalised over the worklist
  `W` and accumulated set `R`: running the loop from `(R, W)` with
  `W ⊆ R ⊆ aliases` reaches `(R*, ∅)` where `R*` is the least set containing
  `R` and closed under `refs(·)` restricted to annotation aliases.
- **soundness side condition (the counter bound):** `seen` grows monotonically
  and is bounded by the finite `set(annotations)`; each alias is pushed at most
  once (`alias not in seen` guard). Decreasing measure
  `|annotations| − |seen|` ⇒ **termination** (PO6).

## 4. Human-readable summary

For every queryset, `count()`/`exists()` after the fix return the same value
as before, because annotations are dropped only when provably row-count-neutral:
**aggregates** (their forced GROUP BY collapses multiplication) and
**join-free non-aggregates** (Concat of local fields, `F('local')`, `Q(...)`,
scalar `Subquery`). A non-aggregate annotation that walks a multi-valued
relation is **kept** (V2 fix), preserving the documented `count()==len(qs)`
invariant. Annotations referenced by filters, ordering, grouping, **DISTINCT
ON**, or other kept/unselected annotations are kept. The transitive-reference
closure terminates.
