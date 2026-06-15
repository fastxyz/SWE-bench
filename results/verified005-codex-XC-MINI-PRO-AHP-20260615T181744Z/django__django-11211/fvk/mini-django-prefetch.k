module MINI-DJANGO-PREFETCH-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Class ::= Foo | OtherClass
  syntax Value ::= None | Str(String) | UUID(String)
                 | uuidPrep(Value) [function]
  syntax Key ::= key(Value, Class)
               | gfkKey(Value, Class) [function]
               | relKey(Value, Class) [function]

  syntax Bool ::= validUuid(String) [function]
                | keysMatch(Value, Value, Class) [function]
  syntax String ::= canonUuid(String) [function]
  syntax KResult ::= Bool | Value | Key
endmodule

module MINI-DJANGO-PREFETCH
  imports MINI-DJANGO-PREFETCH-SYNTAX
  imports BOOL
  imports STRING
  imports K-EQUAL

  configuration <k> $PGM:K </k>

  // Mini semantics for the part of UUIDField used by the issue.
  rule uuidPrep(None) => None
  rule uuidPrep(UUID(S:String)) => UUID(canonUuid(S))
    requires validUuid(S)
  rule uuidPrep(Str(S:String)) => UUID(canonUuid(S))
    requires validUuid(S)

  // Mini semantics for GenericForeignKey's Python-side prefetch join key.
  rule gfkKey(FK:Value, C:Class) => key(uuidPrep(FK), C)
  rule relKey(PK:Value, C:Class) => key(PK, C)
  rule keysMatch(FK:Value, PK:Value, C:Class) => gfkKey(FK, C) ==K relKey(PK, C)
endmodule
