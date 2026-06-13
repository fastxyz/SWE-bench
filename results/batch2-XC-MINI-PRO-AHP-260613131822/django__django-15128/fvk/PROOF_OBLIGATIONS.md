# PROOF_OBLIGATIONS.md — django-15128

The obligations the V1 fix must discharge for the spec in `SPEC.md` to hold.
Each lists: statement, where it is discharged, and status. `[discharged]` =
constructed proof closes it (modulo machine-check); `[escalation]` = beyond the
bundled tier, stated honestly, decisive sub-fact still given; `[assumption]` =
standing external invariant the fix does not rely on or modify.

The top-level goal:

> **G (no-assert).** For every `combine(rhs, connector)` call on the verified
> domain, the `change_map` it builds satisfies
> `set(change_map).isdisjoint(change_map.values())`; hence every
> `change_aliases(change_map)` reached from it (directly, via
> `where.relabel_aliases`, or recursively through queryset subqueries) satisfies
> its `assert` precondition.

G follows from PO-DISJOINT, which follows from PO-KEYS + PO-VALS + PO-PREFIX via
the core structural lemma (PO-LEMMA). The remaining obligations protect the
*other* contracts the fix must not break (non-mutation, equivalence, back-compat,
termination).

---

## PO-LEMMA — core structural disjointness (the heart)
**Statement.** For a map `M` with `keysPref(M, Pr)` (every key is `pref(Pr,_)`),
`valsDom(M, Ps)` (every value is `pref(Ps,_)` or `name(_)`), and `Pr ≠ Ps`:
`keys(M) ∩ values(M) = ∅`.
**Proof.** Take any key `k = pref(Pr,n)` and value `v`. If `v = pref(Ps,m)` then
`k ≠ v` because `Pr ≠ Ps`. If `v = name(t)` then `k ≠ v` because the two are
different constructors (a generated alias bears a digit suffix; a table-name
alias does not). No arithmetic, no table-name/alias-collision assumption needed.
**Where.** `[simplification]` rule in `combine-aliasing-spec.k`; the per-pair core
is constructor disequality (Z3-trivial).
**Status.** `[discharged]` (per-pair). The Map-fold lift is PO-DISJOINT.

## PO-DISJOINT — the loop maintains disjointness to completion
**Statement.** Running `buildChangeMap` from `change_map = {}` over a stream whose
keys are all `pref(Pr,_)` and values all in `dom(Ps)`, with `Pr ≠ Ps`, ends in a
map `M'` with `disjointKV(M') = true`.
**Where.** `(LOOP)` circularity + `(COMBINE)` claim in `combine-aliasing-spec.k`;
proof in `PROOF.md` §3–§4. The loop invariant `keysPref(M,Pr) ∧ valsDom(M,Ps)`
is preserved by each iteration (adding one `pref(Pr,_) |-> dom(Ps)` pair, or
skipping a self-map), and on exit PO-LEMMA gives `disjointKV`.
**Status.** `[discharged]` for the per-step invariant; the induction over the
whole `Map` value (folding `keysPref`/`valsDom`/`disjointKV`) is flagged
`[escalation]` in PROOF.md §6 (Map-induction is outside the bundled arithmetic
tier — like insertion-sort's multiset VCs) and is **not** faked as `[trusted]`;
the decisive per-step content is fully given.

## PO-PREFIX — the bump yields a prefix distinct from self's  (SC1)
**Statement.** After `if self.alias_prefix == rhs.alias_prefix: …
rhs.bump_prefix(self, …)`, the prefix `Pr` that rhs's keys carry satisfies
`Pr ≠ Ps` where `Ps = self.alias_prefix`.
**Proof.** Two cases on the guard.
- *Equal-prefix (bump runs):* `bump_prefix`'s `prefix_gen` starts at
  `chr(ord(self.alias_prefix)+1)` (strictly after `Ps`) and assigns the first
  candidate not in `subq_aliases`; every candidate is `> Ps`, so `Pr ≠ Ps`. The
  early-return guard inside `bump_prefix`
  (`if self.alias_prefix != other_query.alias_prefix: return`) does *not* trigger
  because the outer guard already made them equal.
- *Different-prefix (bump skipped):* `Pr = rhs.alias_prefix ≠ Ps` by the guard.
**Status.** `[discharged]` (code inspection of `bump_prefix` + the guard).

## PO-KEYS — every change_map key is a generated alias `pref(Pr,_)`  (SC2)
**Statement.** Every alias in `rhs_tables = list(rhs.alias_map)[1:]` (the only
possible change_map keys) is `pref(Pr,_)` — no key is a bare `name(_)`.
**Proof.**
- *Bump branch:* `bump_prefix` calls `change_aliases({alias: '%sN' % Pr for …
  alias not in exclude})`, relabelling **every** non-excluded alias — including
  first-occurrence table-name aliases — to a generated `pref(Pr,_)`. `exclude` is
  exactly `{rhs.base_table}`, and the base is the *first* `alias_map` entry,
  dropped by `[1:]`. So all of `rhs_tables` are `pref(Pr,_)`.
- *No-bump branch:* reaching it means `rhs.alias_prefix ≠ Ps`, i.e. rhs was
  previously bumped, which likewise relabelled all its non-base aliases to
  `pref(rhs.alias_prefix,_)`. Same conclusion (FINDINGS F4).
**Status.** `[discharged]`. This obligation is what defeats the name-vs-name
corner case (FINDINGS F4): there are simply no `name(_)` keys.

## PO-VALS — every change_map value is `pref(Ps,_)` or `name(_)`
**Statement.** Each `new_alias = self.join(join, reuse=reuse)` recorded as a value
is either a generated alias with `self`'s prefix `Ps`, or a table-name alias.
**Proof.** `self.join` returns either (a) a reused existing alias of `self` — and
`self`'s aliases are all `pref(Ps,_)` or `name(_)` since `self.alias_prefix = Ps`
and `self` is never bumped by the fix — or (b) a fresh alias from
`self.table_alias`, which is `'%sN' % self.alias_prefix = pref(Ps,_)` (table seen
before) or the bare table name `name(_)` (first occurrence). In all cases the
value is `pref(Ps,_)` or `name(_)`. (Values are *never* `pref(Pr,_)`: `self` has
no alias with prefix `Pr`.)
**Status.** `[discharged]` (code inspection of `Query.join` / `Query.table_alias`).

## PO-NOMUT — the original rhs is not mutated  (combine's docstring)
**Statement.** No object reachable from the *caller's* `rhs` is mutated by
`combine`.
**Proof.** When the bump runs, `rhs` is rebound to `rhs.clone()`; all subsequent
`rhs.*` are the clone. `change_aliases` (invoked by `bump_prefix`) touches, on the
clone: `where` (clone is an independent `where.clone()`); `select`/`annotations`/
`external_aliases`/`group_by` (**reassigned** to new objects, originals untouched);
`alias_map`/`alias_refcount` (fresh dicts from `clone()`; values replaced via
`relabeled_clone`, never mutated). The **one** structure `clone()` shares by
reference is `table_map`'s *list* values, which `change_aliases` mutates in
place — so V1 reassigns them to per-list copies on the clone *before* the bump
(FINDINGS F6). Hence nothing reachable from the original rhs changes.
**Status.** `[discharged]` (enumerated every structure `change_aliases` writes).

## PO-EQUIV — the combined query equals the pre-fix intended query
**Statement.** The final `change_map` *values* (hence the final aliases of the
combined query) are the same as the (non-crashing) pre-fix code would have
produced; the bump only renames the intermediate *keys*.
**Proof.** Values come from `self.join`, driven by `join.table_name`, `reuse`, and
`join.equals(...)`. The bump changes only rhs alias *names* (and their parents,
consistently), not join structure; `relabeled_clone(change_map)` rewrites a
bumped rhs join's parent to the *same* final value a non-bumped parent would map
to. So `self.join` returns the same `new_alias` sequence, and `self.alias_map`
(never bumped) is identical. Keys differ (`pref(Pr,_)` vs `pref(Ps,_)`) but are
only used to relabel rhs's `where`/`select`, which end up referencing the same
final value aliases. (Worked numerically in `reports/baseline_notes.md`.)
**Status.** `[discharged]` (structural argument; the values are a function of
join structure, which the bump preserves).

## PO-TERM — termination (partial-correctness recommendation)
**Statement.** `buildChangeMap` terminates.
**Proof sketch.** The loop is `for alias in rhs_tables` over a finite list; each
iteration consumes one element (`<pairs>` strictly shrinks, measure
`size(rhs_tables) - i`, bounded below by 0, strictly decreasing). `bump_prefix`'s
search is bounded by `local_recursion_limit`. No unbounded recursion.
**Status.** `[discharged-by-inspection]`; FVK default is partial correctness, so
this is a recommendation, not part of the reachability proof.

## PO-BACKCOMPAT — `bump_prefix(other_query)` unchanged for old callers
**Statement.** Existing callers `clone.bump_prefix(query)` and
`query.bump_prefix(self)` behave exactly as before V1.
**Proof.** `exclude=None ⇒ {} ⇒ (alias not in {}) ≡ True` for all aliases ⇒ the
relabelling set is identical to the old `{alias: '%sN' % P for pos,alias in
enumerate(alias_map)}`. Positional call ⇒ rename `outer_query→other_query` is
invisible. No caller uses `outer_query=` (repo-wide grep). 
**Status.** `[discharged]` (FINDINGS F7).

## PO-A1 — table names never look like generated aliases
**Statement.** No real `db_table` equals `'<prefix><number>'`.
**Status.** `[assumption]` — a standing Django-wide invariant. **V1 neither
relies on it for disjointness (PO-LEMMA is constructor-based) nor modifies it.**
Listed for completeness.
