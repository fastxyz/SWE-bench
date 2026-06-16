# FVK Findings

Status: constructed, not machine-checked.

## F-001: Resolved parent mutation for defaulted alternate keys

- Classification: code bug found in the pre-V1 implementation; resolved by V1.
- Input/state: unsaved parent with a non-primary
  `UUIDField(default=uuid.uuid4, editable=False, unique=True)` and an inline
  child FK using `to_field` to that UUID field.
- Observed pre-V1: inline form construction selected the alternate field as
  `to_field`, saw `has_default()`, and executed
  `setattr(self.instance, to_field.attname, None)`, mutating the parent UUID to
  `None`.
- Expected: the parent alternate UUID must remain available for saving the
  parent and linking the inline child.
- Evidence: E1, E2, E3 in `fvk/SPEC.md`.
- Proof obligations: PO-001 and PO-006.
- V1 status: satisfied by clearing only `to_field.primary_key` fields and using
  `kwargs["initial"] = None` for defaulted non-PK `to_field` values.

## F-002: Empty hidden initial value is still required

- Classification: compatibility and validation requirement; satisfied by V1.
- Input/state: unsaved parent whose relation target has a Python default.
- Observed risk in a naive fix: simply removing the mutation for all `to_field`
  cases would preserve the parent UUID but render that generated unsaved UUID as
  the hidden inline initial value.
- Expected: the hidden inline initial remains empty for default-generated
  unsaved relation targets, including alternate-key relations.
- Evidence: E4 and E5 in `fvk/SPEC.md`.
- Proof obligations: PO-002, PO-003, and PO-004.
- V1 status: satisfied by passing an explicit `initial=None` for defaulted
  non-PK `to_field` values and making `InlineForeignKeyField` honor explicit
  `initial`.

## F-003: No API compatibility issue found

- Classification: compatibility audit.
- Input/state: public or internal callers constructing `InlineForeignKeyField`
  without an explicit `initial`.
- Observed V1 behavior: callers without `initial` still receive the old behavior
  of deriving initial from `parent_instance.to_field` or `parent_instance.pk`.
- Expected: no signature change and no behavior change outside the explicit
  override case.
- Evidence: `InlineForeignKeyField.__init__()` still has the same signature and
  accepts `**kwargs`; no other callsite supplies `initial`.
- Proof obligations: PO-004 and PO-007.
- V1 status: satisfied; no further source edit is justified.

## F-004: Proof is constructed but not machine-checked

- Classification: proof capability and process limitation.
- Input/state: all formal claims in `fvk/inline-formset-spec.k`.
- Observed: per task constraints, no `kompile`, `kast`, `kprove`, Python, or
  Django test command was run.
- Expected: artifacts must provide exact commands and mark the proof as
  constructed, not machine-checked.
- Evidence: FVK `verify.md` honesty gate and the task's no-execution rule.
- Proof obligations: PO-008.
- V1 status: no source-code impact; keep tests and run the emitted commands only
  in an environment where execution is allowed.
