requires "mini-inbulk.k"

module IN-BULK-SPEC
  imports MINI-INBULK

  // SPEC-PROVENANCE:
  // - E1/E2: total single-field UniqueConstraint must qualify.
  // - E3/E4: non-unique single keys must still reject.
  // - E7: field name and attname are both valid local identifiers.

  claim <k> validate("pk", field(NAME:String, ATT:String, UNIQUE:Bool), CS:Constraints)
        => allow ... </k>
    [all-path]

  claim <k> validate(FIELDNAME:String, field(NAME:String, ATT:String, true), CS:Constraints)
        => allow ... </k>
    requires FIELDNAME =/=String "pk"
    [all-path]

  claim <k> validate(FIELDNAME:String, field(NAME:String, ATT:String, false), uc(NAME, true), CS:Constraints)
        => allow ... </k>
    requires FIELDNAME =/=String "pk"
    [all-path]

  claim <k> validate(FIELDNAME:String, field(NAME:String, ATT:String, false), uc(ATT, true), CS:Constraints)
        => allow ... </k>
    requires FIELDNAME =/=String "pk"
    [all-path]

  claim <k> validate(FIELDNAME:String, field(NAME:String, ATT:String, false), CS:Constraints)
        => reject ... </k>
    requires FIELDNAME =/=String "pk"
     andBool notBool singleTotalMatches(NAME, ATT, CS)
    [all-path]
endmodule
