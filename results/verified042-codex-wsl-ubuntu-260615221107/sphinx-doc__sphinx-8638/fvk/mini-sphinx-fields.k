// Minimal K model for sphinx-doc__sphinx-8638.
// Status: constructed, not machine-checked.

module MINI-SPHINX-FIELDS-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Role ::= "noRole" | "objRole" | "classRole" | "dataRole" | "constRole" | "attrRole"
  syntax Objects ::= "noSameName"
                   | "moduleSameName"
                   | "sameClassSameName"
                   | "otherClassSameName"

  syntax Node ::= "plain" "(" String ")"
                | "pending" "(" Role "," String ")"
                | "linked" "(" String "," String ")"
                | "renderedField" "(" Node "," Node ")"
                | "renderedFieldWithType" "(" Node "," Node "," Node ")"

  syntax Command ::= "variableField" "(" Role "," String "," String "," Objects ")"
                   | "variableFieldWithType" "(" Role "," Role "," String "," String "," String "," Objects ")"
                   | "explicitReference" "(" Role "," String "," Objects ")"

  syntax KResult ::= Node
endmodule

module MINI-SPHINX-FIELDS
  imports MINI-SPHINX-FIELDS-SYNTAX

  configuration <k> $PGM:Command </k>

  // Field.make_xref(): no role means no pending_xref is created.
  rule <k> variableField(noRole, NAME:String, BODY:String, OBJECTS:Objects)
        => renderedField(plain(NAME), plain(BODY)) </k>

  // Legacy shape: a role on the variable field label creates a pending xref.
  rule <k> variableField(objRole, NAME:String, BODY:String, noSameName)
        => renderedField(pending(objRole, NAME), plain(BODY)) </k>
  rule <k> variableField(objRole, NAME:String, BODY:String, moduleSameName)
        => renderedField(linked(NAME, "module-data"), plain(BODY)) </k>
  rule <k> variableField(objRole, NAME:String, BODY:String, sameClassSameName)
        => renderedField(linked(NAME, "same-class-object"), plain(BODY)) </k>
  rule <k> variableField(objRole, NAME:String, BODY:String, otherClassSameName)
        => renderedField(linked(NAME, "other-class-object"), plain(BODY)) </k>

  // V1 shape: variable label is plain, but vartype keeps a class-role xref.
  rule <k> variableFieldWithType(noRole, classRole, NAME:String, TYPE:String,
                                 BODY:String, OBJECTS:Objects)
        => renderedFieldWithType(plain(NAME), pending(classRole, TYPE), plain(BODY)) </k>

  // Explicit user roles are still allowed to resolve.
  rule <k> explicitReference(dataRole, NAME:String, moduleSameName)
        => linked(NAME, "module-data") </k>
  rule <k> explicitReference(constRole, NAME:String, moduleSameName)
        => linked(NAME, "module-const") </k>
  rule <k> explicitReference(attrRole, NAME:String, sameClassSameName)
        => linked(NAME, "same-class-attr") </k>
endmodule
