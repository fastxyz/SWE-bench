# SPEC.md — formal specification of the V1 fix (django__django-15268)

**Status:** constructed, not machine-checked (FVK MVP). The Findings (benefit 2) do
not depend on machine-checking; the test-redundancy advice (benefit 1) is conditioned
on running the emitted `kompile`/`kprove` commands.

K artifacts: [`optimizer.k`](optimizer.k) (mini-Python fragment semantics),
[`optimizer-spec.k`](optimizer-spec.k) (the claims + simplification lemmas).

---

## 1. What is being specified

The V1 fix adds one method to `django/db/migrations/operations/models.py`:

```python
class AlterTogetherOptionOperation(ModelOptionOperation):
    ...
    def reduce(self, operation, app_label):
        return super().reduce(operation, app_label) or (
            isinstance(operation, AlterTogetherOptionOperation) and
            self.name_lower == operation.name_lower
        )
```

`AlterTogetherOptionOperation` is the shared base of exactly two operations
(`AlterUniqueTogether`, `AlterIndexTogether` — confirmed: no other subclasses exist,
and `CreateModel.reduce` at models.py:153 already treats them uniformly through this
base class). The method participates in the migration optimizer
(`django/db/migrations/optimizer.py`), whose `reduce` protocol is:

| `a.reduce(b)` returns | meaning to the optimizer |
|---|---|
| a **list** `[…]` | replace `a` (and `b`) with the listed operations (a *reduction*) |
| `True` | `a` and `b` are independent; `a` may be **optimized across** `b` (reordered) |
| `False` | `a` is a **barrier**; stop scanning |

## 2. The intended behaviour (intent-spec)

From `benchmark/PROBLEM.md`: the autodetector splits each `AlterFooTogether` change
into a *remove* op then an *add* op (issue #31503), producing the interleaved list

```
AlterUniqueTogether(m, ∅)   AlterIndexTogether(m, ∅)   AlterUniqueTogether(m, {c})   AlterIndexTogether(m, {c})
```

which must optimize to `AlterUniqueTogether(m, {c}), AlterIndexTogether(m, {c})`.
The two `AlterUniqueTogether` ops are separated by an `AlterIndexTogether` (and
vice-versa); collapsing each pair requires the optimizer to **optimize the
in-between operation across** the merge — i.e. `reduce` must report that an
`AlterUniqueTogether` and an `AlterIndexTogether` on the same model are independent.

## 3. Function contract — `reduce`  (claims REDUCE-\* in `optimizer-spec.k`)

For operands `a = self` (always an `AlterFooTogether`) and `b = operation`, with
- `sameModel  = (a.name_lower == b.name_lower)`
- `sameKind   = isinstance(b, type(a))`  (i.e. U vs U, or I vs I)
- `bTogether  = isinstance(b, AlterTogetherOptionOperation)`

the contract is the total function:

| case | `bTogether` | `sameModel` | `sameKind` | result | claim |
|---|---|---|---|---|---|
| same kind, same model | T | T | T | `[b]` (collapse) | REDUCE-COLLAPSE |
| diff model | * | F | * | `True` (commute) | REDUCE-COMMUTE-DIFFMODEL |
| **same model, diff kind** | **T** | **T** | **F** | **`True` (commute)** | **REDUCE-COMMUTE-SAMEMODEL** ← the fix |
| same model, non-together `b` | F | T | * | `False` (barrier) | REDUCE-SCOPE |

**Precondition:** none beyond well-typed operands (the function is *total* — defined
for every combination of the three booleans). The single behavioural change vs. V0 is
the third row: it used to be `False`, the fix makes it `True`.

## 4. Soundness side condition — `commute` requires disjointness (claim COMMUTE)

`reduce` may return `True` ("optimize across") only when `a` and `b` are genuinely
**independent**. The justifying lemma:

> **COMMUTE.** For two `AlterFooTogether` ops with `(a.kind, a.model) ≠ (b.kind, b.model)`,
> `apply(a); apply(b)` and `apply(b); apply(a)` reach the **same** model-options state
> and emit independent database effects.

Modelled in `optimizer.k`: `apply(op(K,M,V))` writes the single store slot
`slot(K,M) ← V` and logs `eff(K,M,V)`. Because `slot(U,M)` and `slot(I,M)` are
**distinct keys**, the two updates commute (map update on distinct keys is
order-independent — lemma VC-DISJOINT). This mirrors the real code exactly:
`state_forwards` calls `state.alter_model_options(app_label, name, {option_name: value})`,
which merges a **single key** (`unique_together` *or* `index_together`) into the
options dict (`state.py:170`), and `database_forwards` calls
`schema_editor.alter_unique_together` resp. `alter_index_together`, which manage
**disjoint database objects** (unique constraints vs. indexes). The `True` verdict is
returned exactly on the rows of §3 where this disjointness holds (diff model ⇒ different
model entirely; same model + diff kind ⇒ `slot(U,M) ≠ slot(I,M)`), so the side
condition is always met. **Importantly**, the verdict is gated on
`isinstance(b, AlterTogetherOptionOperation)`, so a field operation (`AddField`,
`AlterField`) on the same model is **never** declared independent (REDUCE-SCOPE),
which is what preserves the #31503 remove-then-add split.

## 5. Optimizer-level contracts

- **OPT-TERM (termination, claim in `optimizer-spec.k`).** `MigrationOptimizer.optimize`
  runs `optimize_inner` in a `while True` loop until `result == operations`. Each pass
  that changes anything performs exactly one reduction, which removes ≥ 1 operation;
  the list length is bounded below by 0. Hence the number of changing passes ≤ the
  initial length: the loop terminates. The fix only *enables more* reductions (each
  still strictly shortens the list), so it cannot break termination. Modelled as the
  down-counting variant loop (shape of `examples/03-sum-down`).

- **OPT-SOUND (partial correctness, stated; core discharged, full = escalation).**
  If `reduce` is a correct classifier (REDUCE-\* + COMMUTE), then `optimize` returns a
  list with the **same net effect** as the input: every reduction either drops a
  superseded op (collapse) or reorders independent ops (commute), neither of which
  changes the final model state or the multiset of database effects. The per-step
  justification is COLLAPSE + COMMUTE, which we discharge; the full inductive
  equivalence over arbitrary operation lists and the real migration-state model is
  marked `[ESCALATION BOUNDARY]` (see PROOF.md §5).

## 6. Trusted base

The mini-Python fragment in `optimizer.k` is an **abstraction** of the real code:
operations are reduced to `(kind, model, value)` triples and the model-options state to
a key→value map. The proof is therefore relative to (a) the faithfulness of that
abstraction, (b) the K reachability metatheory + `kprove`, and (c) the SMT/simplification
oracle. Everything is labelled *constructed, not machine-checked*.
