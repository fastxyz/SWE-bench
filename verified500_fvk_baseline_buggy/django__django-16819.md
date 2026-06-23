# django__django-16819

## Summary

**Severity:** Low — baseline reduces a matching `AddIndex`/`RemoveIndex` pair but
misses the adjacent `AddIndex` + `RenameIndex` composition, so an
add/rename/remove sequence leaves redundant migration operations rather than a
wrong final database state.

Baseline and FVK both passed the official SWE-bench evaluation for issue #16819,
with **different** patches. The FVK patch added a second reduction —
`AddIndex` followed by `RenameIndex` of the same just-added index composes into a
single `AddIndex` with the final name — that the baseline patch left out, and did
so while preserving public subclasses such as `AddIndexConcurrently`. The defect
is minor (extra migration operations, never a wrong schema); the case matters
because FVK located the gap by **formalizing the reduction as an algebra and
auditing every composition the issue implies**, not by running more tests.

| Arm | add/rename/remove reduces to `[]` | Resolved |
|---|---|---|
| baseline | partial — pair cancels, rename does not compose | no |
| gold (human oracle) | (no curated gold patch for this run) | — |
| **fvk** | composes via the new `RenameIndex` branch | **yes** |

## 1. The issue and the real defect

**Django issue #16819 — "Reduce Add/RemoveIndex migration operations."** The
migration optimizer should collapse index operations the way it already collapses
field operations: an index that is added and later removed in the same
optimization window has no net effect and should disappear
([`prompts/fvk.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/prompts/fvk.md#L2)).
(The existing report carried no GitHub URL, so none is asserted here.)

`django/db/migrations/operations/models.py` defines `AddIndex`, `RemoveIndex`,
and `RenameIndex` as `IndexOperation` subclasses. Before any fix, none of them
implemented an optimizer `reduce()`, so the optimizer could not collapse index
operations at all — adding then removing the same index left both operations in
the migration. The user-facing observable is **redundant, un-squashed migration
operations** that a human would otherwise expect the optimizer to remove.

## 2. Baseline's fix — and where it stopped

[Baseline](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/solutions/solution_baseline.patch)
added the model-reference protocol to `IndexOperation` plus a single reducer on
`AddIndex` that cancels a matching `RemoveIndex`:

```python
def reduce(self, operation, app_label):
    if (
        isinstance(operation, RemoveIndex)
        and self.model_name_lower == operation.model_name_lower
        and self.index.name == operation.name
    ):
        return []
    return super().reduce(operation, app_label)
```

Baseline was not careless. Its notes show it deliberately scoped the reduction to
the exact reported pair and consciously left broader cases alone:

> *"I assumed the intended reduction is only safe when the `RemoveIndex` targets
> the exact index name added by `AddIndex`. … I rejected a broader same-model
> field-level pass-through because indexes can depend on fields through
> expressions, conditions, and includes, and the current issue does not require
> that extra analysis."*
> — [`reports/baseline_notes.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/reports/baseline_notes.md#L33)

That reasoning is sound for the field-level boundary it names. But it overlooked a
case **inside** the index algebra itself: when an index is added and then
*renamed* before being removed, the `RenameIndex` sits between the add and the
remove and references the same model, so baseline's pass-through returns `False`
and the optimizer stalls — the add and remove can never meet. Baseline stopped
one reduction short of the obligation its own scope implied.

## 3. How FVK formally captured the gap

FVK started from an intent ledger, not the symptom. The decisive item generalizes
the issue from "cancel add+remove" to "compose any index operation onto the add
it follows":

> **I5:** *"A rename of an index added earlier in the same optimization window
> should compose into the add operation, preserving the index payload with the
> final name."*
> — [`fvk/SPEC.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/SPEC.md#L30)

The same ledger pins that intent to a concrete code fact found by source audit of
the existing optimizer — `RenameIndex` already composes consecutive renames, so an
add immediately followed by a rename of that index is the symmetric missing case:

> *I5 source: "existing index optimizer behavior — `RenameIndex.reduce()`
> composes consecutive index renames."*
> — [`fvk/SPEC.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/SPEC.md#L30)

Which is discharged into a formal obligation over every concrete add class:

> **PO-4: Add/rename composition.** *"For all canonical model names `M`, exact
> index names `Old` and `New`, … and concrete add operation class `C` …
> `C(M, Index(name=Old, payload=P)).reduce(RenameIndex(M, new_name=New,
> old_name=Old))` returns `[C(M, Index(name=New, payload=P))]`."*
> — [`fvk/PROOF_OBLIGATIONS.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/PROOF_OBLIGATIONS.md#L40)

This is the crux of FVK's value here: **the missing reduction was located by
reasoning, not observation.** The issue asks to reduce add/remove; FVK lifts that
into an algebra over every contributor to the index operation stream, and the
audit shows the add/rename composition (PO-4) is a second reduction the optimizer
needs for an add/rename/remove sequence to fully collapse.

## 4. From formal output to the fix

The FVK arm's repair is iterative, and the artifacts record the exact step where
the formalism changed the patch.

- **V1** (first attempt) shipped only the add/remove reducer — identical in spirit
  to baseline. The completeness audit against I5/PO-4 raised a finding:

  > **FVK-F1: V1 missed add/rename/remove composition.** *"`AddIndex.reduce(RenameIndex(...))`
  > fell through to `IndexOperation.reduce()`. Because `RenameIndex` references the
  > same model, the pass-through result was `False`. The optimizer could not compose
  > the newly added index with its rename, so the later `RemoveIndex("new_idx")`
  > could not cancel the add."*
  > — [`fvk/FINDINGS.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/FINDINGS.md#L6)

- A second finding caught a compatibility trap in the first V2 edit — returning a
  plain `AddIndex` would erase the `AddIndexConcurrently` class:

  > **FVK-F1b: Rename composition must preserve AddIndex subclasses.** *"Returning
  > `[AddIndex(...)]` would preserve final state but drop the public
  > `AddIndexConcurrently` operation class and its concurrent database behavior."*
  > — [`fvk/FINDINGS.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/FINDINGS.md#L42)

- The iteration guidance turned both findings into the instruction for V2:

  > *"Extend `AddIndex.reduce()` with a `RenameIndex` branch. Clone the existing
  > index, assign `operation.new_name`, and return a single operation of
  > `self.__class__` with the renamed clone, preserving public subclasses such as
  > `AddIndexConcurrently`."*
  > — [`fvk/ITERATION_GUIDANCE.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/ITERATION_GUIDANCE.md#L13)

- The decision log records the change and its provenance:

  > *"Added an `AddIndex.reduce(RenameIndex)` branch. This is justified by FVK-F1,
  > PO-4, and PO-7 … Constructed the rename replacement with
  > `self.__class__(self.model_name, index)` … justified by FVK-F1b, PO-6, and
  > PO-11."*
  > — [`reports/fvk_notes.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/reports/fvk_notes.md#L17)

The causal chain is fully on the record:

```
SPEC I5  ->  E (code audit: RenameIndex.reduce already composes renames)
         ->  FVK-F1 (V1 audit: add+rename does not compose; remove cannot cancel)
         ->  PO-4   (obligation: add+rename => single add with final name)
         ->  FVK-F1b/PO-11 (preserve concrete add subclass)
         ->  ITERATION_GUIDANCE / fvk_notes  ->  V2 patch
```

The resulting [V2 patch](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/solutions/solution_fvk.patch)
adds the `RenameIndex` branch on top of baseline's `RemoveIndex` branch:

```python
if (
    isinstance(operation, RenameIndex)
    and self.model_name_lower == operation.model_name_lower
    and operation.old_name
    and self.index.name == operation.old_name
):
    index = self.index.clone()
    index.name = operation.new_name
    return [self.__class__(self.model_name, index)]
```

The `V1 -> V2` transition was driven by `FVK-F1`/`PO-4`, **not** by a new failing
test — the prompt forbids editing tests and there is no add/rename/remove
optimizer test in the run (see §5).

## 5. Verification

**Tier 3 — source-and-artifact reviewed; not executed.** This run produced no
harness RED/GREEN reports (census `proof=no`, no curated `_proof` directory) and
no executed demonstration table; the prompt explicitly bars running tests, Python,
or K tooling
([`prompts/fvk.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/prompts/fvk.md#L26)).
What was inspected:

- The two patches were diffed: the FVK patch is baseline plus exactly the nine-line
  `RenameIndex` branch shown above
  ([`solution_baseline.patch`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/solutions/solution_baseline.patch),
  [`solution_fvk.patch`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/solutions/solution_fvk.patch)).
- The optimizer-level composition is reasoned out by hand in the proof sketch:
  applying C2 then C1 to `AddIndex -> RenameIndex -> RemoveIndex` reduces the
  window to `[]`
  ([`fvk/PROOF.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/PROOF.md#L108)).

**Gold comparison.** This run is non-curated, so there is no gold patch file to
diff against. The existing report's claim — that FVK added a reduction beyond
baseline — is confirmed against the patches themselves; no claim about the human
oracle's contents is made, since that artifact is absent here.

## 6. Boundaries & honesty

- **Severity: Low.** The trigger breadth is narrow and the failure mode is benign:
  the gap only fires on an `AddIndex` immediately composable with a `RenameIndex`
  of the same just-added index, and the worst outcome is **redundant migration
  operations**, never a wrong final database state
  ([`fvk/FINDINGS.md` FVK-F1](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/FINDINGS.md#L6)).
  The value demonstrated is detection completeness, not impact magnitude.
- **Proof status: constructed, not machine-checked.** The K artifacts
  ([`mini-migration-optimizer.k`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/mini-migration-optimizer.k),
  [`migration-optimizer-spec.k`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/migration-optimizer-spec.k))
  and the `kompile`/`kast`/`kprove` commands were *written but never run* — the
  FVK artifacts say so explicitly
  ([`fvk/PROOF.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/PROOF.md#L1),
  [finding FVK-F6](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/FINDINGS.md#L167)).
  We claim **proof-structured reasoning** (a formal algebra with obligations
  discharged by construction), **not a machine-checked proof**.
- **Retained limitation, stated as such.** Same-model unrelated index/field
  commutation is intentionally *not* implemented — FVK classifies it as a
  conservative boundary (PO-9 / FVK-F5), matching baseline's own rejection of that
  broader analysis
  ([`fvk/FINDINGS.md` FVK-F5](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/FINDINGS.md#L140)).
- **Attribution.** The `V1 -> V2` iteration is documented across `FINDINGS.md`,
  `ITERATION_GUIDANCE.md`, and `fvk_notes.md`; the discrepancy with the existing
  report is only structural (the old doc was a bullet list, this restates the same
  facts as a chain) — no claim was reversed.

## Artifact map

| Claim | Source |
|---|---|
| Issue / task statement | [`prompts/fvk.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/prompts/fvk.md#L2) |
| Baseline patch | [`solutions/solution_baseline.patch`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/solutions/solution_baseline.patch) |
| Baseline reasoning (exact-name scope) | [`reports/baseline_notes.md`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/reports/baseline_notes.md#L33) |
| FVK patch | [`solutions/solution_fvk.patch`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/solutions/solution_fvk.patch) |
| Intent I5 (rename composition) | [`fvk/SPEC.md#L30`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/SPEC.md#L30) |
| Obligation PO-4 | [`fvk/PROOF_OBLIGATIONS.md#L40`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/PROOF_OBLIGATIONS.md#L40) |
| Finding FVK-F1 (V1 gap) | [`fvk/FINDINGS.md#L6`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/FINDINGS.md#L6) |
| Finding FVK-F1b (subclass preservation) | [`fvk/FINDINGS.md#L42`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/FINDINGS.md#L42) |
| Iteration instruction (V1→V2) | [`fvk/ITERATION_GUIDANCE.md#L13`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/ITERATION_GUIDANCE.md#L13) |
| Decision trace | [`reports/fvk_notes.md#L17`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/reports/fvk_notes.md#L17) |
| Optimizer-level composition sketch | [`fvk/PROOF.md#L108`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/PROOF.md#L108) |
| Retained limitation (FVK-F5) | [`fvk/FINDINGS.md#L140`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/FINDINGS.md#L140) |
| Proof status (not machine-checked) | [`fvk/PROOF.md#L1`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/PROOF.md#L1), [`fvk/FINDINGS.md#L167`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/FINDINGS.md#L167) |
| Constructed K core | [`fvk/mini-migration-optimizer.k`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/mini-migration-optimizer.k), [`fvk/migration-optimizer-spec.k`](../results/verified025-codex-archlinux-20260616T064857Z/django__django-16819/fvk/migration-optimizer-spec.k) |
