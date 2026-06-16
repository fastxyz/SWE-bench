module MINI-AUTODOC-TYPEHINTS-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports STRING-SYNTAX

  syntax ObjType ::= "class" | "exception" | "function" | "method" | "other"
  syntax MaybeType ::= "noReturn" | "returnType" "(" String ")"
  syntax ParamAnn ::= "paramAnn" "(" Id "," String ")"
  syntax ParamAnns ::= ".ParamAnns" | ParamAnn ParamAnns [right]
  syntax Signature ::= "signature" "(" ParamAnns "," MaybeType ")"

  syntax KItem ::= "recordTypehints" "(" ObjType "," Signature ")"
                 | "mergeTypehints"

  syntax Bool ::= "classLike" "(" ObjType ")" [function]
endmodule

module MINI-AUTODOC-TYPEHINTS
  imports MINI-AUTODOC-TYPEHINTS-SYNTAX
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:K </k>
    <recordedParams> .ParamAnns </recordedParams>
    <recordedReturn> false </recordedReturn>
    <rtypeEmitted> false </rtypeEmitted>

  rule classLike(class) => true
  rule classLike(exception) => true
  rule classLike(function) => false
  rule classLike(method) => false
  rule classLike(other) => false

  rule <k> recordTypehints(KIND, signature(PARAMS, noReturn)) => .K ... </k>
       <recordedParams> _ => PARAMS </recordedParams>
       <recordedReturn> _ => false </recordedReturn>

  rule <k> recordTypehints(KIND, signature(PARAMS, returnType(R))) => .K ... </k>
       <recordedParams> _ => PARAMS </recordedParams>
       <recordedReturn> _ => false </recordedReturn>
    requires classLike(KIND)

  rule <k> recordTypehints(KIND, signature(PARAMS, returnType(R))) => .K ... </k>
       <recordedParams> _ => PARAMS </recordedParams>
       <recordedReturn> _ => true </recordedReturn>
    requires notBool classLike(KIND)

  rule <k> mergeTypehints => .K ... </k>
       <recordedReturn> false </recordedReturn>
       <rtypeEmitted> _ => false </rtypeEmitted>

  rule <k> mergeTypehints => .K ... </k>
       <recordedReturn> true </recordedReturn>
       <rtypeEmitted> _ => true </rtypeEmitted>
endmodule
