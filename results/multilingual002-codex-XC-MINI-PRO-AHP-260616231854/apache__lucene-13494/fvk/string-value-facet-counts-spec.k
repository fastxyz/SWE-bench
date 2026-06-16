requires "mini-java-facet.k"

module STRING-VALUE-FACET-COUNTS-SPEC
  imports MINI-JAVA-FACET

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-003: no-hit valid field must return zero child count, not NPE.
  // - E-006/E-007: both count stores null is a valid empty-count representation.
  claim
    <k> getTopChildren(N:Int, F:String, emptyPath) => facetResult(F, 0, 0) </k>
    <storage> none </storage>
    <field> F </field>
    <totalDocCount> 0 </totalDocCount>
    requires N >Int 0
    [all-path, label(TOP-EMPTY)]

  // SPEC-PROVENANCE:
  // - E-001/E-002: the same empty state must not dereference denseCounts.
  claim
    <k> getAllChildren(F:String, emptyPath) => facetResult(F, 0, 0) </k>
    <storage> none </storage>
    <field> F </field>
    <totalDocCount> 0 </totalDocCount>
    [all-path, label(ALL-EMPTY)]

  // SPEC-PROVENANCE:
  // - E-005: an existing value path returns its count; with no hits that count is 0.
  claim
    <k> getSpecificValue(F:String, present(ORD:Int)) => specificValue(0) </k>
    <storage> none </storage>
    <field> F </field>
    <totalDocCount> 0 </totalDocCount>
    requires ORD >=Int 0
    [all-path, label(SPECIFIC-PRESENT-EMPTY)]

  // SPEC-PROVENANCE:
  // - E-005: absent paths return -1 before count storage is consulted.
  claim
    <k> getSpecificValue(F:String, absentTerm) => specificValue(-1) </k>
    <storage> STORAGE:Storage </storage>
    <field> F </field>
    <totalDocCount> T:Int </totalDocCount>
    [all-path, label(SPECIFIC-ABSENT)]

  // SPEC-PROVENANCE:
  // - E-008: non-empty dense storage remains on the existing counting path.
  claim
    <k> getTopChildren(N:Int, F:String, emptyPath) => facetResult(F, T, C) </k>
    <storage> dense(C) </storage>
    <field> F </field>
    <totalDocCount> T </totalDocCount>
    requires N >Int 0 andBool C >=Int 0
    [all-path, label(TOP-DENSE-FRAME)]

  // SPEC-PROVENANCE:
  // - E-008: non-empty sparse storage remains on the existing counting path.
  claim
    <k> getTopChildren(N:Int, F:String, emptyPath) => facetResult(F, T, C) </k>
    <storage> sparse(C) </storage>
    <field> F </field>
    <totalDocCount> T </totalDocCount>
    requires N >Int 0 andBool C >=Int 0
    [all-path, label(TOP-SPARSE-FRAME)]
endmodule
