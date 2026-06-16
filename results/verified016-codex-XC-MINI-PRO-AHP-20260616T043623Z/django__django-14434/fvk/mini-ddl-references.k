module MINI-DDL-REFERENCES-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax TableKey ::= raw(String) | wrapped(String)
  syntax Cols ::= ".Cols" | col(String, Cols)
  syntax NameMode ::= explicitName | generatedName

  syntax Ref ::= tablePart(TableKey)
               | columnsPart(TableKey, Cols)
               | indexNamePart(TableKey, Cols)
               | quotedName
               | otherPart

  syntax Refs ::= ".Refs" | refs(Ref, Refs)
  syntax Statement ::= stmt(Refs)

  syntax KResult ::= Bool | String | TableKey | Cols | NameMode | Ref | Refs | Statement
endmodule

module MINI-DDL-REFERENCES
  imports MINI-DDL-REFERENCES-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:K </k>

  syntax Bool ::= contains(String, Cols) [function]
  rule contains(C:String, .Cols) => false
  rule contains(C:String, col(C:String, _CS:Cols)) => true
  rule contains(C:String, col(D:String, CS:Cols)) => contains(C, CS)
    requires C =/=String D

  syntax Bool ::= tableKeyEq(TableKey, TableKey) [function]
  rule tableKeyEq(raw(T:String), raw(U:String)) => T ==String U
  rule tableKeyEq(wrapped(T:String), wrapped(U:String)) => T ==String U
  rule tableKeyEq(raw(_T:String), wrapped(_U:String)) => false
  rule tableKeyEq(wrapped(_T:String), raw(_U:String)) => false

  syntax Bool ::= referencesColumn(Ref, TableKey, String) [function]
  rule referencesColumn(tablePart(_T:TableKey), _Q:TableKey, _C:String) => false
  rule referencesColumn(quotedName, _Q:TableKey, _C:String) => false
  rule referencesColumn(otherPart, _Q:TableKey, _C:String) => false
  rule referencesColumn(columnsPart(T:TableKey, CS:Cols), Q:TableKey, C:String)
    => tableKeyEq(T, Q) andBool contains(C, CS)
  rule referencesColumn(indexNamePart(T:TableKey, CS:Cols), Q:TableKey, C:String)
    => tableKeyEq(T, Q) andBool contains(C, CS)

  syntax Bool ::= refsReferenceColumn(Refs, TableKey, String) [function]
  rule refsReferenceColumn(.Refs, _Q:TableKey, _C:String) => false
  rule refsReferenceColumn(refs(R:Ref, RS:Refs), Q:TableKey, C:String)
    => referencesColumn(R, Q, C) orBool refsReferenceColumn(RS, Q, C)

  syntax Bool ::= stmtReferencesColumn(Statement, TableKey, String) [function]
  rule stmtReferencesColumn(stmt(RS:Refs), Q:TableKey, C:String)
    => refsReferenceColumn(RS, Q, C)

  syntax Statement ::= createUniqueV2(String, Cols, NameMode) [function]
  rule createUniqueV2(T:String, CS:Cols, explicitName)
    => stmt(refs(tablePart(raw(T)),
         refs(quotedName,
         refs(columnsPart(raw(T), CS), .Refs))))
  rule createUniqueV2(T:String, CS:Cols, generatedName)
    => stmt(refs(tablePart(raw(T)),
         refs(indexNamePart(raw(T), CS),
         refs(columnsPart(raw(T), CS), .Refs))))

  syntax Statement ::= createUniqueV1(String, Cols, NameMode) [function]
  rule createUniqueV1(T:String, CS:Cols, explicitName)
    => stmt(refs(tablePart(wrapped(T)),
         refs(quotedName,
         refs(columnsPart(wrapped(T), CS), .Refs))))
  rule createUniqueV1(T:String, CS:Cols, generatedName)
    => stmt(refs(tablePart(wrapped(T)),
         refs(indexNamePart(raw(T), CS),
         refs(columnsPart(wrapped(T), CS), .Refs))))

  syntax TableKey ::= renderedTableKey(Statement) [function]
  rule renderedTableKey(stmt(refs(tablePart(T:TableKey), _RS:Refs))) => T
endmodule
