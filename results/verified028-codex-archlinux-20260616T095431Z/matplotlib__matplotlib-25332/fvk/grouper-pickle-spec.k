requires "mini-python-grouper.k"

module GROUPER-PICKLE-SPEC
  imports MINI-PYTHON-GROUPER

  // SPEC-PROVENANCE:
  // - from_prompt: "Expected outcome: Pickling successful"
  //   => pickle-visible Grouper state must not contain weakref.ref objects.
  // - from_code: V1 `__getstate__` returns `list(self)`, modeled as GS.
  claim <k> getstate(grouper(GS:Groups)) => result(GS) </k>
    requires validGroups(GS)
     ensures noWeakRefs(GS)

  // SPEC-PROVENANCE:
  // - from_docs: "Alignment persists for draw events after this is called."
  //   => serialization must preserve the sibling partition.
  // - from_code: V1 `__setstate__` starts from an empty map and joins each group.
  claim <k> setstate(GS:Groups) => result(GS) </k>
    requires validGroups(GS) andBool disjointGroups(GS)

  // SPEC-PROVENANCE:
  // - loop invariant for `for group in state: self.join(*group)`.
  // - ACC is the partition already rebuilt; TODO is the unprocessed suffix.
  claim <k> joinAll(ACC:Groups, TODO:Groups) => result(appendGroups(ACC, TODO)) </k>
    requires validGroups(ACC) andBool validGroups(TODO)
endmodule
