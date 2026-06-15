# FVK Findings

Status: constructed, not machine-checked.

## F1: Pre-fix setter left stale parent PK values

- Classification: code bug in legacy behavior.
- Evidence: `benchmark/PROBLEM.md` reports that resetting a child-model primary
  key still overwrites the existing object on `save()`.
- Mechanism: the old `_set_pk_val()` wrote only `self._meta.pk.attname`. For an
  MTI child, `_save_parents()` and parent `_save_table()` also consult inherited
  parent PK attnames such as `id` or `uid`.
- Concrete state: `Derived.item_ptr_id = None`, `Derived.uid = old` before
  save means the parent table still has `pk_val = old`, so `_save_table()`
  attempts an update.
- Expected: `Derived.item_ptr_id = None` and `Derived.uid = None`.
- Resolution: V1 addresses this by walking the primary-key parent-link chain.

## F2: V1 satisfies the primary-key chain obligation

- Classification: confirmed candidate behavior.
- Evidence: V1 assigns the value to the current field and follows
  `field.target_field` while `field.remote_field.parent_link` is true.
- Proof obligation: PO1 and PO2.
- Result: for one-level and multi-level MTI primary-key chains, all chain PK
  attnames are assigned the same value.
- Code decision: no source change required.

## F3: Resetting every parent link would be over-broad

- Classification: compatibility risk avoided.
- Evidence: public hints say the all-parents patch failed for child models that
  inherit from multiple models and caused other failures. Django source also
  has models where the parent-link connector need not be the child PK.
- Expected: `pk` assignment should affect the model primary-key alias and its
  parent PK chain, not every parent relationship.
- Resolution: V1 remains narrower than the all-parent patch.

## F4: Direct inherited field assignment remains outside the proven contract

- Classification: residual ambiguity / possible future feature.
- Evidence: the issue's first code sample uses `self.uid = None`, but public
  discussion reframes the reliable API as `self.pk = None`.
- Observed under current design: assigning the inherited concrete field directly
  does not necessarily clear the child parent-link field.
- Expected under this FVK spec: callers use `pk = None` for the reliable MTI
  copy operation.
- Recommendation: do not broaden V1 without a separate public requirement,
  because doing so would require descriptor/save-path changes outside the
  `pk` setter contract.

## F5: Multiple independent concrete parents are not fully specified by `pk`

- Classification: underspecified intent / test gap.
- Evidence: public hints reject an all-parent reset, but the user also wanted a
  reliable copy mechanism for MTI.
- Analysis: `pk` denotes a single model primary-key alias. In models with
  additional non-primary parent links, resetting those links may be necessary
  for a full graph copy but is not entailed by `pk` alias semantics and risks
  compatibility regressions.
- Resolution: V1 intentionally proves only the active primary-key chain.
- Recommendation: add explicit public tests or docs before changing non-primary
  parent-link reset behavior.

## Proof-derived findings from `/verify`

- No proof obligation forced a source change beyond V1.
- Termination of the setter loop relies on Django's finite acyclic model
  inheritance metadata. This is a standard implementation invariant from
  `ModelBase`/`Options`, not a runtime condition introduced by the patch.
- The proof is constructed only. `kompile`/`kprove` were not run, per task
  constraints.
