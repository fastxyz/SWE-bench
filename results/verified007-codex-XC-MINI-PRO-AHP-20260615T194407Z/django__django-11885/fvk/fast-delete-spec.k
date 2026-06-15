requires "mini-fast-delete.k"

module MINI-FAST-DELETE-SPEC
  imports MINI-FAST-DELETE

  // SPEC-PROVENANCE:
  // - from_prompt: "both queries ... can be combined into a single one by using OR"
  //   => compatible fast deletes for the same model/table combine by OR.
  // - from_code: Collector.add_fast_delete() scans fast_deletes and replaces the
  //   first compatible entry with fast_delete | qs.
  claim
    <k> addFast(
          fd(Entry, created_by, known(A)) ; REST,
          fd(Entry, updated_by, known(B)),
          bounded(Max)
        )
      => fd(Entry, created_by |or| updated_by, known(A +Int B)) ; REST
    </k>
    requires A >=Int 0 andBool B >=Int 0 andBool A +Int B <=Int Max
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: self many-to-many example requires from_id/to_id predicates
  //   for the same through table to become one OR predicate.
  claim
    <k> addFast(
          fd(PersonFriends, from_id, known(1)) ; .FDs,
          fd(PersonFriends, to_id, known(1)),
          bounded(Max)
        )
      => fd(PersonFriends, from_id |or| to_id, known(2)) ; .FDs
    </k>
    requires Max >=Int 2
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_api: QuerySet.__or__ combines only compatible querysets for
  //   the same model; incompatible fast deletes must stay separate.
  claim
    <k> addFast(
          fd(Entry, created_by, known(A)) ; .FDs,
          fd(OtherModel, other_pred, known(B)),
          unbounded
        )
      => fd(Entry, created_by, known(A)) ;
         fd(OtherModel, other_pred, known(B)) ; .FDs
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: V1 tracks parameter counts to avoid constructing a combined
  //   query over a backend's max_query_params.
  claim
    <k> addFast(
          fd(Entry, created_by, known(A)) ; .FDs,
          fd(Entry, updated_by, known(B)),
          bounded(Max)
        )
      => fd(Entry, created_by, known(A)) ;
         fd(Entry, updated_by, known(B)) ; .FDs
    </k>
    requires A >=Int 0 andBool B >=Int 0 andBool A +Int B >Int Max
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: Collector.delete() executes one _raw_delete() call per final
  //   fast_deletes entry; combining two entries must reduce round trips to one.
  claim
    <k> rawDeleteCount(
          addFast(
            fd(Entry, created_by, known(1)) ; .FDs,
            fd(Entry, updated_by, known(1)),
            bounded(Max)
          )
        )
      => 1
    </k>
    requires Max >=Int 2
    [all-path]
endmodule
