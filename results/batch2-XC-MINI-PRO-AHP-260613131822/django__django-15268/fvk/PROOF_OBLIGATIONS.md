# PROOF_OBLIGATIONS.md — django__django-15268

Each obligation has: statement, why it matters, discharge status, and the evidence
that discharges it. Status ∈ {DISCHARGED, DISCHARGED (core) / ESCALATION,
DOCUMENTED-INVARIANT}. "constructed, not machine-checked."

---

### PO-COLLAPSE — same kind + same model collapses to the later op
**Statement.** `AlterFooTogether a`, `b` with `sameKind ∧ sameModel` ⇒
`a.reduce(b) = [b]`.
**Why.** Pre-existing optimization (`test_alter_alter_unique_model` /
`test_alter_alter_index_model`); must be preserved by the fix.
**Discharge.** DISCHARGED. `super().reduce()` (`ModelOptionOperation.reduce`) returns
`[operation]` here; the fix's `or` short-circuits on the truthy list and never reaches
the new clause. Claim REDUCE-COLLAPSE. See FINDINGS F1.

### PO-COMMUTE — the `True` verdict is semantically sound (disjointness)
**Statement.** For `AlterFooTogether a, b` with `(a.kind,a.model) ≠ (b.kind,b.model)`,
`apply(a);apply(b) ≡ apply(b);apply(a)` (same final model-options state; database
effects are on disjoint objects).
**Why.** The optimizer reorders an operation across another precisely when `reduce`
returns `True`; if the two did not commute, the reordering would corrupt the migration.
This is *the* soundness condition for the fix.
**Discharge.** DISCHARGED. (1) State: `state_forwards` merges a single, kind-specific
key (`unique_together` xor `index_together`) into the options dict
(`state.py:170`, `alter_model_options`); distinct keys ⇒ updates commute (lemma
VC-DISJOINT). (2) DB: `database_forwards` calls `alter_unique_together` vs
`alter_index_together`, managing disjoint database objects (unique constraints vs
indexes). Claim COMMUTE + lemma VC-DISJOINT. See FINDINGS F2.

### PO-FIX — same model + different kind ⇒ `True` (the change itself)
**Statement.** `AlterFooTogether a, b`, both together-ops, `sameModel ∧ ¬sameKind` ⇒
`a.reduce(b) = True`.
**Why.** This is the exact behaviour the issue needs; was `False` in V0, blocking the
optimization.
**Discharge.** DISCHARGED. `super().reduce()` returns `False` (same model, not same
subclass), so the `or` evaluates the new clause:
`isinstance(b, AlterTogetherOptionOperation) ∧ sameModel = True ∧ True = True`.
Claim REDUCE-COMMUTE-SAMEMODEL. Soundness of the resulting reorder = PO-COMMUTE.

### PO-SCOPE — the fix does NOT collapse across non-together ops (#31503 preserved)
**Statement.** `AlterFooTogether a`, non-`AlterTogetherOptionOperation` `b` (e.g.
`AddField`/`AlterField`) with `sameModel` ⇒ `a.reduce(b) = False` (unchanged from V0).
**Why.** #31503 deliberately splits remove/add around field alterations; if the fix made
`a` commute across a field op, an alteration of a field still referenced by a
unique/index constraint could be reordered, breaking that fix.
**Discharge.** DISCHARGED. The new clause is gated on
`isinstance(b, AlterTogetherOptionOperation)`, which is `False` for field ops, so the
`or` yields `super().reduce()`'s value unchanged. Claim REDUCE-SCOPE. See FINDINGS F3.

### PO-DIFFMODEL — different model ⇒ `True` (unchanged)
**Statement.** `sameModel = False` ⇒ `a.reduce(b) = True`, identical to V0.
**Why.** Confirms the fix is purely additive on the same-model axis; no regression.
**Discharge.** DISCHARGED. `super().reduce()` = `ModelOperation.reduce` returns
`not b.references_model(a.name) = not False = True`; the `or` short-circuits before the
new clause. Claim REDUCE-COMMUTE-DIFFMODEL.

### PO-NOSHADOW — `super().reduce()` is never a *falsy non-`False`* value
**Statement.** In `super().reduce(operation, app_label) or (…)`, `super().reduce()`
∈ {a non-empty list, `True`, `False`} for an `AlterFooTogether` self — it is never `[]`,
`0`, `None`, or `""`.
**Why.** Python's `or` treats `[]` as falsy. If `super()` could return `[]` (meaning
"delete both ops"), the `or` would wrongly fall through and return `True`, silently
turning a deletion into a no-op reorder — a latent shadowing bug.
**Discharge.** DOCUMENTED-INVARIANT (cannot occur). Walking the chain:
`ModelOptionOperation.reduce` returns `[operation]` (1-element, non-empty) or delegates;
`ModelOperation.reduce` returns `Operation.reduce(...) or not references_model(...)`,
i.e. a bool, or `[self]`/`[operation]` (non-empty) when an operand is `elidable`;
`Operation.reduce` returns `[operation]`, `[self]`, or `False`. No path yields `[]`.
(`[]` is produced only by `CreateModel.reduce` for CreateModel+DeleteModel, never in this
chain.) Modelled by the `super ∈ {collapse,commute,barrier}` assumption in
`optimizer-spec.k`. See FINDINGS F4 — kept as a finding, no code change (the idiom
matches `ModelOperation.reduce`/`RenameModel.reduce`).

### PO-TERM — the optimizer fixpoint loop terminates
**Statement.** `MigrationOptimizer.optimize` halts on every input; each `optimize_inner`
pass returns a list of length ≤ its input.
**Why.** The optimizer's contract ("return a list of equal or shorter length"); the fix
must not introduce non-termination.
**Discharge.** DISCHARGED. Variant = list length, bounded below by 0; a changing pass
performs one reduction removing ≥ 1 op, so #passes ≤ initial length. The fix only adds a
`True` verdict, which never *creates* operations — it can only enable further
length-decreasing reductions — so the variant argument is unaffected. Claim OPT-TERM
(down-counting circularity). See FINDINGS F5.

### PO-OPT-SOUND — `optimize` preserves net migration semantics
**Statement.** Given a correct `reduce` classifier, `optimize(ops)` yields a list whose
net effect (final model state + multiset of database effects) equals that of `ops`.
**Why.** The optimizer must not change what the migration does.
**Discharge.** DISCHARGED (per-step core) / ESCALATION (full induction). Each optimizer
rewrite is either a collapse (drops an op superseded by a later same-kind+model op —
PO-COLLAPSE) or a commute-reorder (PO-COMMUTE), neither of which changes net semantics.
The optimizer's right/left-reduction guards (`right` stays True only while every
in-between op verdict is truthy; the left branch requires
`all(op.reduce(other) is True …)`) ensure a reorder happens only across ops that
actually commute. The full inductive equivalence over arbitrary lists + the real
`ProjectState`/`SchemaEditor` model is `[ESCALATION BOUNDARY]` (recursive-data /
relational reasoning beyond the bundled arithmetic tier). See PROOF.md §5, FINDINGS F6.
