requires "domains.md"

module MINI-DJANGO-SCHEMA-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Collation ::= noCollation() | collation(String)
  syntax Params ::= params(String, Bool, Collation)
  syntax Field ::= field(String, Bool, Bool, Bool, Bool, Params)
  syntax Sql ::= columnSql(String, Collation, Bool)
               | alterSql(String, Collation, Bool)
               | noSql()

  syntax Params ::= fkParams(Field) [function]
  syntax Bool ::= dropIncomingFks(Field, Field) [function]
  syntax Sql ::= createColumnSql(Field) [function]
  syntax Sql ::= relatedAlterSql(Field) [function]
endmodule

module MINI-DJANGO-SCHEMA
  imports MINI-DJANGO-SCHEMA-SYNTAX
  imports BOOL
  imports STRING

  // field(Type, Null, PrimaryKey, Unique, DbConstraint, TargetParams)
  // Params are params(Type, Check, Collation).

  rule fkParams(field(TYPE, _NULL, _PK, _UNIQUE, _DBC, TARGET))
    => params(TYPE, false, targetCollation(TARGET))

  syntax Collation ::= targetCollation(Params) [function]
  rule targetCollation(params(_TYPE, _CHECK, COLLATION)) => COLLATION

  syntax Bool ::= typeChanged(Field, Field) [function]
  rule typeChanged(field(OLDTYPE, _, _, _, _, _), field(NEWTYPE, _, _, _, _, _))
    => OLDTYPE =/=String NEWTYPE

  syntax Bool ::= collationChanged(Field, Field) [function]
  rule collationChanged(
      field(_, _, _, _, _, params(_, _, OLDCOLLATION)),
      field(_, _, _, _, _, params(_, _, NEWCOLLATION))
    )
    => OLDCOLLATION =/=K NEWCOLLATION

  syntax Bool ::= retainedPkOrUnique(Field, Field) [function]
  rule retainedPkOrUnique(field(_, _, true, _, _, _), field(_, _, true, _, _, _)) => true
  rule retainedPkOrUnique(field(_, _, false, true, _, _), field(_, _, false, true, _, _)) => true
  rule retainedPkOrUnique(_, _) => false [owise]

  rule dropIncomingFks(OLD, NEW)
    => retainedPkOrUnique(OLD, NEW)
       andBool (typeChanged(OLD, NEW) orBool collationChanged(OLD, NEW))

  rule createColumnSql(field(TYPE, NULL, _PK, _UNIQUE, _DBC, params(_, _, COLLATION)))
    => columnSql(TYPE, COLLATION, NULL)

  rule relatedAlterSql(field(TYPE, NULL, _PK, _UNIQUE, _DBC, params(_, _, COLLATION)))
    => alterSql(TYPE, COLLATION, NULL)
endmodule
