# Proof Obligations

Status: constructed, not machine-checked.

PO1. Reverse many-to-one async dispatch.

- Claim: For every `Op` in `{create, getOrCreate, updateOrCreate}`, calling
  `invokeAsync(reverseFK, Op, T)` reaches `reverseFkEffect(Op)`.
- Source obligations: I1, I2, E2, E4, E5.
- Discharge: V1 defines local async methods on `RelatedManager` that call
  `sync_to_async(self.create)`, `sync_to_async(self.get_or_create)`, and
  `sync_to_async(self.update_or_create)`.
- Related finding: F1.

PO2. Many-to-many async dispatch and `through_defaults` preservation.

- Claim: For every `Op` and `ThroughDefaults` value `T`, calling
  `invokeAsync(manyToMany, Op, T)` reaches `manyToManyEffect(Op, T)`.
- Source obligations: I1, I2, I3, E2, E4, E6, E7.
- Discharge: V1 defines local async methods on `ManyRelatedManager` and
  forwards `through_defaults=through_defaults` to the sync method.
- Related finding: F2.

PO3. Generic related manager async dispatch.

- Claim: For every `Op`, calling `invokeAsync(genericRel, Op, T)` reaches
  `genericEffect(Op)`.
- Source obligations: I4, E4, E8.
- Discharge: V1 defines local async methods on `GenericRelatedObjectManager`
  that call its existing sync methods through `sync_to_async`.
- Related finding: F3.

PO4. Plain manager/queryset frame condition.

- Claim: For every `Op`, calling `invokeAsync(plain, Op, T)` reaches
  `querysetProxyEffect(Op)`.
- Source obligations: I5, E9.
- Discharge: V1 does not edit `BaseManager._get_queryset_methods()`,
  `Manager`, or `QuerySet`.
- Related finding: F4.

PO5. Public signature compatibility.

- Claim: The new local async wrappers accept the same public argument family as
  their corresponding sync related-manager methods.
- Source obligations: I2-I4, E7, compatibility audit.
- Discharge: reverse FK and generic wrappers use `**kwargs`, matching sync
  related-manager methods; m2m wrappers use
  `*, through_defaults=None, **kwargs`, matching m2m sync methods.
- Related findings: F1-F3.

PO6. Mutating method marker.

- Claim: Every new related-manager async wrapper has `alters_data = True`.
- Source obligations: I6, E10.
- Discharge: V1 sets `acreate.alters_data`, `aget_or_create.alters_data`, and
  `aupdate_or_create.alters_data` in each generated related manager class.
- Related findings: F1-F3.

PO7. No hidden dependency on tests or execution.

- Claim: The conclusion that V1 stands follows from public issue text, public
  source, public tests used as intent evidence, and constructed proof
  obligations only.
- Source obligations: FVK methodology and benchmark constraints.
- Discharge: no tests, Python, or K tooling were run; no test files were
  modified.

