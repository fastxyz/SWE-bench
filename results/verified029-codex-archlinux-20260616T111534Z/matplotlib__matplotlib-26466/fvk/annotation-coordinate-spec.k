requires "mini-python.k"

module ANNOTATION-COORDINATE-SPEC
  imports MINI-PYTHON

  // SPEC-PROVENANCE:
  // - from_prompt: "changing the array after calling the function changes the
  //   arrow position" is reported as the bug.
  // - from_prompt: "Both arrows should be horizontal" means the stored
  //   annotation endpoint must stay at the construction-time coordinate.
  // - from_docs_or_tests: text.pyi exposes _AnnotationBase.xy as
  //   tuple[float, float].
  // - from_code: _AnnotationBase.__init__ stores tuple(xy).
  claim [annotation-base-xy-copy-y]:
    <k> storeAnnXY(arr(A)) ~> mutate(arr(A), 1, scalar(Y2)) => .K </k>
    <heap> arr(A) |-> pair(scalar(X), scalar(Y))
        => arr(A) |-> pair(scalar(X), scalar(Y2)) </heap>
    <annotationXY> none => tup(scalar(X), scalar(Y)) </annotationXY>
    requires A >=Int 0

  // Same frame property for the x component.
  claim [annotation-base-xy-copy-x]:
    <k> storeAnnXY(arr(A)) ~> mutate(arr(A), 0, scalar(X2)) => .K </k>
    <heap> arr(A) |-> pair(scalar(X), scalar(Y))
        => arr(A) |-> pair(scalar(X2), scalar(Y)) </heap>
    <annotationXY> none => tup(scalar(X), scalar(Y)) </annotationXY>
    requires A >=Int 0

  // SPEC-PROVENANCE:
  // - from_prompt_hint: "A similar issue is maybe present in the definition of
  //   OffsetFrom helper class."
  // - from_docs_or_tests: OffsetFrom.ref_coord is documented and typed as a
  //   two-coordinate tuple.
  // - from_code: OffsetFrom.__init__ stores tuple(ref_coord).
  claim [offsetfrom-ref-copy-y]:
    <k> storeOffsetRef(arr(A)) ~> mutate(arr(A), 1, scalar(Y2)) => .K </k>
    <heap> arr(A) |-> pair(scalar(X), scalar(Y))
        => arr(A) |-> pair(scalar(X), scalar(Y2)) </heap>
    <offsetRef> none => tup(scalar(X), scalar(Y)) </offsetRef>
    requires A >=Int 0

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: AnnotationBbox.xy and xybox are documented as
  //   "(float, float)", and xybox defaults to xy.
  // - from_code: AnnotationBbox.__init__ now copies explicit xybox and uses
  //   self.xy for the default.
  claim [annotationbbox-explicit-xybox-copy-y]:
    <k> storeXYBox(arr(A)) ~> mutate(arr(A), 1, scalar(Y2)) => .K </k>
    <heap> arr(A) |-> pair(scalar(X), scalar(Y))
        => arr(A) |-> pair(scalar(X), scalar(Y2)) </heap>
    <xybox> none => tup(scalar(X), scalar(Y)) </xybox>
    requires A >=Int 0

  claim [annotationbbox-default-xybox-uses-copied-xy]:
    <k> storeAnnXY(arr(A)) ~> defaultXYBox ~> mutate(arr(A), 1, scalar(Y2)) => .K </k>
    <heap> arr(A) |-> pair(scalar(X), scalar(Y))
        => arr(A) |-> pair(scalar(X), scalar(Y2)) </heap>
    <annotationXY> none => tup(scalar(X), scalar(Y)) </annotationXY>
    <xybox> none => tup(scalar(X), scalar(Y)) </xybox>
    requires A >=Int 0

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: ConnectionPatch.xy1 and xy2 are typed as
  //   tuple[float, float].
  // - from_code: ConnectionPatch.__init__ stores tuple(xyA) and tuple(xyB).
  claim [connectionpatch-endpoints-copy-y]:
    <k> storeConnection(arr(A), arr(B))
         ~> mutate(arr(A), 1, scalar(YA2))
         ~> mutate(arr(B), 1, scalar(YB2)) => .K </k>
    <heap> arr(A) |-> pair(scalar(XA), scalar(YA))
           arr(B) |-> pair(scalar(XB), scalar(YB))
        => arr(A) |-> pair(scalar(XA), scalar(YA2))
           arr(B) |-> pair(scalar(XB), scalar(YB2)) </heap>
    <xy1> none => tup(scalar(XA), scalar(YA)) </xy1>
    <xy2> none => tup(scalar(XB), scalar(YB)) </xy2>
    requires A >=Int 0 andBool B >=Int 0 andBool A =/=Int B
endmodule
