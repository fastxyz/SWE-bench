# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
static source inspection, and the constructed proof obligations. No tests,
Python, or K tooling were run.

## F-001: Annotation masks must not imply explicit RHS selection

- Classification: resolved code bug from the original issue.
- Evidence: E-001 through E-004 in `fvk/SPEC.md`.
- Input/state: RHS query built by `filter(...).annotate(...).alias(...)`, with
  no `values()` or `values_list()`, then used in `book__in=rhs`.
- Pre-V1 observed behavior: `has_select_fields` was inferred from
  `annotation_select_mask`, so the materialized mask made base `In` skip pk
  narrowing; the subquery could return many columns.
- Expected behavior: base `In` treats the RHS selected fields as undefined and
  narrows the RHS to pk.
- V1 audit result: discharged by PO-001. `has_select_fields` now defaults to
  `False`, and `add_annotation()` does not set it.
- Recommended code action: keep V1 unchanged for this point.

## F-002: Related non-primary-key `__in` must mark its target selection

- Classification: resolved regression risk.
- Evidence: E-005 in `fvk/SPEC.md`.
- Input/state: related `__in` RHS query with no explicit values-style selection
  and a relation target field that is not the primary key.
- Risk if only `has_select_fields` changed: `RelatedIn` would select the target
  with `add_fields()`, but base `In.get_prep_lookup()` would still see
  `has_select_fields == False` and overwrite the target with pk.
- Expected behavior: relation-specific target selection survives delegation to
  base `In`.
- V1 audit result: discharged by PO-003. `RelatedIn` now calls
  `rhs.set_values([target_field])`, which both selects the field and sets
  `has_select_fields = True`.
- Recommended code action: keep V1 unchanged for this point.

## F-003: Clone propagation does not require a bespoke assignment

- Classification: confirmed no-op decision.
- Evidence: E-006 in `fvk/SPEC.md`; `Query.clone()` copies `self.__dict__`.
- Input/state: query after `set_values()` has instance attribute
  `has_select_fields = True`, then is cloned and used by base `In`.
- Expected behavior: clone preserves explicit selected-field state.
- V1 audit result: discharged by PO-004. Because `set_values()` writes an
  instance attribute, `obj.__dict__ = self.__dict__.copy()` carries it.
- Recommended code action: do not add a redundant explicit clone assignment.

## F-004: Base `In` and `Exact` pk injection should remain default lookup behavior

- Classification: confirmed no-op decision.
- Evidence: E-002 and E-003 in `fvk/SPEC.md`.
- Input/state: RHS query with undefined selected fields reaches base `In` or a
  sliced one-row `Exact` lookup.
- Expected behavior: lookup preparation injects pk as a default one-column
  selection, but this does not need to become a user values-style selection.
- V1 audit result: discharged by PO-002 and PO-006. The only downstream base
  overwrite risk was `RelatedIn`, which V1 addresses with `set_values()`.
- Recommended code action: do not change base `In` or `Exact` to use
  `set_values(["pk"])`.

## F-005: Compatibility surface remains internal

- Classification: compatibility confirmed.
- Evidence: E-007 in `fvk/SPEC.md`.
- Input/state: public queryset APIs calling through internal query and lookup
  preparation.
- Expected behavior: no public signature, return shape, or documented API
  contract changes.
- V1 audit result: discharged by PO-005. The patch changes private query state
  and an internal related lookup helper call only.
- Recommended code action: no compatibility code changes.

## F-006: Proof remains constructed, not machine-checked

- Classification: proof capability gap.
- Evidence: task instruction forbids K tooling and tests.
- Input/state: all proof obligations.
- Expected behavior: artifacts include exact commands and label the proof
  honestly.
- Audit result: satisfied by `fvk/PROOF.md` and `fvk/SPEC.md`.
- Recommended code action: none. Recommended validation after this benchmark
  setting: run the emitted K commands and Django's relevant ORM tests.

## Open Findings

No open production-code finding was identified by this FVK pass. V1 stands.
