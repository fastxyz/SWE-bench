// Constructed mini semantics for the Django ORM outer-reference scope slice.
// This file was not machine-checked in this environment.

module MINI-ORM-SCOPE-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Ref ::= FRef(String)
               | OuterRef(Ref)
               | Resolved(String)
               | Bound(Int, String)
               | Literal(String)
               | splitShift(Ref)                 [function]
               | splitShiftV0(Ref)               [function]
               | resolveStep(Ref, Int)           [function]
               | pipeline(Ref, Int, Int, Int)    [function]
               | pipelineV0(Ref, Int, Int, Int)  [function]

  syntax KResult ::= Ref
endmodule

module MINI-ORM-SCOPE
  imports MINI-ORM-SCOPE-SYNTAX
  imports INT
  imports STRING

  configuration <k> $PGM:Ref </k>

  // V1 split_exclude() shift.
  rule splitShift(OuterRef(R:Ref)) => OuterRef(OuterRef(R))
  rule splitShift(FRef(N:String)) => OuterRef(FRef(N))
  rule splitShift(Resolved(N:String)) => Resolved(N)
  rule splitShift(Bound(Q:Int, N:String)) => Bound(Q, N)
  rule splitShift(Literal(N:String)) => Literal(N)

  // V0 behavior for comparison: OuterRef fell through the F branch and lost
  // the extra level needed by a generated split_exclude() subquery.
  rule splitShiftV0(OuterRef(FRef(N:String))) => OuterRef(FRef(N))
  rule splitShiftV0(FRef(N:String)) => OuterRef(FRef(N))
  rule splitShiftV0(Resolved(N:String)) => Resolved(N)
  rule splitShiftV0(Bound(Q:Int, N:String)) => Bound(Q, N)
  rule splitShiftV0(Literal(N:String)) => Literal(N)

  // One resolution pass. Query id is an abstract query level:
  // 0 = generated split query, 1 = immediate parent query, 2 = enclosing query.
  rule resolveStep(OuterRef(OuterRef(R:Ref)), Q:Int) => OuterRef(R)
  rule resolveStep(OuterRef(FRef(N:String)), Q:Int) => Resolved(N)
  rule resolveStep(Resolved(N:String), Q:Int) => Bound(Q, N)
  rule resolveStep(FRef(N:String), Q:Int) => Bound(Q, N)
  rule resolveStep(Bound(Q0:Int, N:String), Q:Int) => Bound(Q0, N)
  rule resolveStep(Literal(N:String), Q:Int) => Literal(N)

  // The relevant lifecycle:
  // 1. split_exclude() shifts the RHS for the generated nested query.
  // 2. query.add_filter() resolves inside the generated split query.
  // 3. attaching the generated query resolves against the immediate parent.
  // 4. resolving the parent query as an Exists/Subquery resolves against the enclosing query.
  rule pipeline(R:Ref, Generated:Int, Parent:Int, Enclosing:Int)
    => resolveStep(resolveStep(resolveStep(splitShift(R), Generated), Parent), Enclosing)

  rule pipelineV0(R:Ref, Generated:Int, Parent:Int, Enclosing:Int)
    => resolveStep(resolveStep(resolveStep(splitShiftV0(R), Generated), Parent), Enclosing)
endmodule

