module MINI-PYREVERSE-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Type ::= "NoneType"
                | "Uninferable"
                | "builtin" "(" Id ")"
                | "user" "(" Id ")"

  syntax Types ::= ".Types"
                 | "types" "(" Type "," Types ")"

  syntax Ann ::= "noAnn" | "ann" "(" Type ")"

  syntax Cmd ::= "collectAssignName"
               | "collectAssignAttr"
               | "render"
endmodule

module MINI-PYREVERSE
  imports MINI-PYREVERSE-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:Cmd </k>
    <valueTypes> .Types </valueTypes>
    <annAssign> noAnn </annAssign>
    <paramAnn> noAnn </paramAnn>
    <collected> .Types </collected>
    <diagramTypes> .Types </diagramTypes>
    <displayed> .Types </displayed>

  syntax Types ::= annTypes(Ann) [function]
  rule annTypes(noAnn) => .Types
  rule annTypes(ann(T:Type)) => types(T, .Types)

  syntax Types ::= merge(Types, Types) [function]
  rule merge(.Types, TS:Types) => TS
  rule merge(types(T:Type, REST:Types), TS:Types) => types(T, merge(REST, TS))

  syntax Bool ::= contains(Types, Type) [function]
  rule contains(.Types, _:Type) => false
  rule contains(types(T:Type, _:Types), T) => true
  rule contains(types(T1:Type, REST:Types), T2:Type) => contains(REST, T2)
    requires T1 =/=K T2

  syntax Bool ::= hiddenForDisplay(Type, Types) [function]
  rule hiddenForDisplay(NoneType, _:Types) => true
  rule hiddenForDisplay(Uninferable, _:Types) => true
  rule hiddenForDisplay(T:Type, DIAGRAM:Types) => contains(DIAGRAM, T)
    requires T =/=K NoneType andBool T =/=K Uninferable

  syntax Types ::= visible(Types, Types) [function]
  rule visible(.Types, _:Types) => .Types
  rule visible(types(T:Type, REST:Types), DIAGRAM:Types) => visible(REST, DIAGRAM)
    requires hiddenForDisplay(T, DIAGRAM)
  rule visible(types(T:Type, REST:Types), DIAGRAM:Types)
    => types(T, visible(REST, DIAGRAM))
    requires notBool hiddenForDisplay(T, DIAGRAM)

  rule
    <k> collectAssignName => .K </k>
    <valueTypes> VALUES:Types </valueTypes>
    <annAssign> ANN:Ann </annAssign>
    <collected> _ => merge(VALUES, annTypes(ANN)) </collected>

  rule
    <k> collectAssignAttr => .K </k>
    <valueTypes> VALUES:Types </valueTypes>
    <annAssign> ANN:Ann </annAssign>
    <paramAnn> PARAM:Ann </paramAnn>
    <collected> _ => merge(merge(VALUES, annTypes(ANN)), annTypes(PARAM)) </collected>

  rule
    <k> render => .K </k>
    <collected> TYPES:Types </collected>
    <diagramTypes> DIAGRAM:Types </diagramTypes>
    <displayed> _ => visible(TYPES, DIAGRAM) </displayed>
endmodule
