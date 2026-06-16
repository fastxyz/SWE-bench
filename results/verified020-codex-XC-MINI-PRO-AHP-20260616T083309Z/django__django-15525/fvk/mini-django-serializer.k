module MINI-DJANGO-SERIALIZER-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Db ::= "defaultDb" | "otherDb" | String
  syntax Pk ::= "missingPk" | "pk" "(" Int ")"
  syntax ModelKind ::= "naturalModel" | "plainModel"
  syntax Data ::= "data" "(" Pk "," Int "," String ")"
  syntax Obj ::= "built" "(" Data ")"
  syntax KItem ::= "buildInstanceV1" "(" ModelKind "," Data "," Db ")"
  syntax KItem ::= "routeRelatedRead" "(" Db ")"
  syntax KResult ::= Obj

  syntax Bool ::= "existsByNaturalKey" "(" ModelKind "," Data "," Db ")" [function]
  syntax Int ::= "existingPk" "(" ModelKind "," Data "," Db ")" [function]
endmodule

module MINI-DJANGO-SERIALIZER
  imports MINI-DJANGO-SERIALIZER-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:K </k>
    <probeDb> defaultDb </probeDb>
    <relatedReadDb> defaultDb </relatedReadDb>
    <lookupDb> defaultDb </lookupDb>

  // V1 natural-primary branch. The temporary object is constructed from DATA,
  // then its database state is set to DB before natural_key() can perform a
  // related read. This is the property that distinguishes V1 from the pre-fix
  // behavior, which left the probe database empty and routed to defaultDb.
  rule
    <k> buildInstanceV1(naturalModel, data(missingPk, AID, TITLE), DB)
      => built(data(pk(existingPk(naturalModel, data(missingPk, AID, TITLE), DB)), AID, TITLE))
      ... </k>
    <probeDb> _ => DB </probeDb>
    <relatedReadDb> _ => DB </relatedReadDb>
    <lookupDb> _ => DB </lookupDb>
    requires existsByNaturalKey(naturalModel, data(missingPk, AID, TITLE), DB)

  // Existing-row lookup miss. Django swallows Model.DoesNotExist and returns an
  // instance from the original DATA without setting a PK.
  rule
    <k> buildInstanceV1(naturalModel, data(missingPk, AID, TITLE), DB)
      => built(data(missingPk, AID, TITLE))
      ... </k>
    <probeDb> _ => DB </probeDb>
    <relatedReadDb> _ => DB </relatedReadDb>
    <lookupDb> _ => DB </lookupDb>
    requires notBool existsByNaturalKey(naturalModel, data(missingPk, AID, TITLE), DB)

  // Present-PK and no-natural-key-support frame cases.
  rule
    <k> buildInstanceV1(MODEL, data(pk(PK), AID, TITLE), DB)
      => built(data(pk(PK), AID, TITLE))
      ... </k>
    <probeDb> DB0 => DB0 </probeDb>
    <relatedReadDb> RDB => RDB </relatedReadDb>
    <lookupDb> LDB => LDB </lookupDb>

  rule
    <k> buildInstanceV1(plainModel, data(missingPk, AID, TITLE), DB)
      => built(data(missingPk, AID, TITLE))
      ... </k>
    <probeDb> DB0 => DB0 </probeDb>
    <relatedReadDb> RDB => RDB </relatedReadDb>
    <lookupDb> LDB => LDB </lookupDb>
endmodule
