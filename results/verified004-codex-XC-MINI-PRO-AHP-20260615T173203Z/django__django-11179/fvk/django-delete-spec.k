requires "mini-django-delete.k"

module DJANGO-DELETE-SPEC
  imports MINI-DJANGO-DELETE
  imports INT
  imports MAP
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "It should be set to None after .delete() call." => postcondition obj pk is nonePk.
  // - from_prompt: "models without any dependencies" => optimized fast-delete path is in scope.
  // - from_code: V1 sequences clearPk after deleteBatch and before return.
  // - conflicts: Pre-V1 omitted clearPk and therefore could not reach the postcondition.
  claim
    <k> singleFastDelete(obj, model, pk(P), C) => .K </k>
    <objPks> obj |-> pk(P) => obj |-> nonePk </objPks>
    <ret> noResult => deleteResult(C, model) </ret>
    requires P >=Int 0 andBool C >=Int 0
    [label(OPT-FAST-SINGLE-CLEAR-PK), all-path]

  // SPEC-PROVENANCE:
  // - from_prompt_hint: "mimics what ... does for multiple objects" => normal cleanup is reference behavior.
  // - from_code: existing normal path sets model._meta.pk.attname to None for every collected instance.
  claim
    <k> normalCollectedDelete(obj ; .Objs, model, C) => .K </k>
    <objPks> obj |-> pk(P) => obj |-> nonePk </objPks>
    <ret> noResult => deleteResult(C, model) </ret>
    requires P >=Int 0 andBool C >=Int 0
    [label(NORMAL-COLLECTED-CLEAR-PK), all-path]
endmodule
