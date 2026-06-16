requires "mini-django-save.k"

module DJANGO-SAVE-SPEC
  imports MINI-DJANGO-SAVE

  // C1: Empty local FK value is refreshed from the saved related object's pk.
  // SPEC-PROVENANCE:
  // - E1-E4: issue trace requires product_id "foo", not "".
  // - E5: public hint identifies empty_values in _prepare_related_fields_for_save().
  // - E6-E7: descriptor/default behavior produces EmptyVal before pk assignment.
  claim
    <k> prepare(true, PK:Val, PK) => .K </k>
    <att> EmptyVal => PK </att>
    <cache> Cached </cache>
    <outcome> Normal </outcome>
    requires PK =/=K NoneVal
    [all-path]

  // C2: Unsaved related object protection is preserved.
  // SPEC-PROVENANCE:
  // - E8: source raises when obj.pk is None.
  // - I3: fix must not weaken the data-loss guard.
  claim
    <k> prepare(true, NoneVal, TARGET:Val) => .K </k>
    <att> ATT:Val </att>
    <cache> Cached </cache>
    <outcome> Normal => ValueError </outcome>
    [all-path]

  // C3: A non-empty stale local FK value doesn't get overwritten, but the
  // relation cache is cleared when target and local values differ.
  // SPEC-PROVENANCE:
  // - E9: existing cache invalidation after comparison.
  // - I4-I5: preserve non-empty-value and mismatch behavior.
  claim
    <k> prepare(true, PK:Val, TARGET:Val) => .K </k>
    <att> ATT:Val </att>
    <cache> Cached => NotCached </cache>
    <outcome> Normal </outcome>
    requires PK =/=K NoneVal
     andBool notBool isEmptyValue(ATT)
     andBool TARGET =/=K ATT
    [all-path]
endmodule
