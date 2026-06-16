module MINI-JAVA-FACET-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Storage ::= "none" | "dense" "(" Int ")" | "sparse" "(" Int ")"
  syntax PathKind ::= "emptyPath" | "onePath" | "badPath"
  syntax Lookup ::= "present" "(" Int ")" | "absentTerm"
  syntax Method ::= "getTopChildren" "(" Int "," String "," PathKind ")"
                  | "getAllChildren" "(" String "," PathKind ")"
                  | "getSpecificValue" "(" String "," Lookup ")"
                  | "hasCountStorage" "(" ")"
                  | "emptyResult" "(" ")"
  syntax Result ::= "facetResult" "(" String "," Int "," Int ")"
                  | "specificValue" "(" Int ")"
                  | "invalid" "(" ")"
  syntax KResult ::= Bool | Result
endmodule

module MINI-JAVA-FACET
  imports MINI-JAVA-FACET-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:Method </k>
    <storage> none </storage>
    <field> "" </field>
    <totalDocCount> 0 </totalDocCount>

  rule <k> hasCountStorage() => false ... </k>
       <storage> none </storage>

  rule <k> hasCountStorage() => true ... </k>
       <storage> dense(_:Int) </storage>

  rule <k> hasCountStorage() => true ... </k>
       <storage> sparse(_:Int) </storage>

  rule <k> emptyResult() => facetResult(F, T, 0) ... </k>
       <field> F </field>
       <totalDocCount> T </totalDocCount>

  rule <k> getTopChildren(N, F, emptyPath) => emptyResult() ... </k>
       <storage> none </storage>
       <field> F </field>
       <totalDocCount> 0 </totalDocCount>
    requires N >Int 0

  rule <k> getAllChildren(F, emptyPath) => emptyResult() ... </k>
       <storage> none </storage>
       <field> F </field>
       <totalDocCount> 0 </totalDocCount>

  rule <k> getSpecificValue(F, present(ORD:Int)) => specificValue(0) ... </k>
       <storage> none </storage>
       <field> F </field>
       <totalDocCount> 0 </totalDocCount>
    requires ORD >=Int 0

  rule <k> getSpecificValue(F, absentTerm) => specificValue(-1) ... </k>
       <field> F </field>

  rule <k> getTopChildren(N, F, emptyPath) => facetResult(F, T, C) ... </k>
       <storage> dense(C) </storage>
       <field> F </field>
       <totalDocCount> T </totalDocCount>
    requires N >Int 0 andBool C >=Int 0

  rule <k> getTopChildren(N, F, emptyPath) => facetResult(F, T, C) ... </k>
       <storage> sparse(C) </storage>
       <field> F </field>
       <totalDocCount> T </totalDocCount>
    requires N >Int 0 andBool C >=Int 0
endmodule
