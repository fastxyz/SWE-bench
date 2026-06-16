module MINI-XARRAY-SYNTAX
  imports BOOL
  imports MAP
  imports SET

  syntax Obj ::= scalar
               | obj(Map, Map, Map)
  // obj(topAttrs, coordAttrsByName, dataVarAttrsByName)

  syntax Value ::= whereValue(Obj, Obj, Obj) [function]

  syntax Result ::= result(Value, Map, Map, Map)
  // result(value, topAttrs, dataVarAttrsByName, coordAttrsByName)

  syntax Result ::= whereKeepAttrsTrue(Obj, Obj, Obj) [function]

  syntax Map ::= attrsOf(Obj) [function]
               | dataAttrsFromX(Obj, Set) [function]
               | coordAttrsOverride(Obj, Obj, Obj) [function]

  syntax Set ::= resultDataVars(Obj, Obj, Obj) [function]
endmodule

module MINI-XARRAY
  imports MINI-XARRAY-SYNTAX

  configuration <k> $PGM:Result </k>

  rule attrsOf(scalar) => .Map
  rule attrsOf(obj(A, _C, _D)) => A

  rule whereKeepAttrsTrue(COND, X, Y)
    => result(
         whereValue(COND, X, Y),
         attrsOf(X),
         dataAttrsFromX(X, resultDataVars(X, COND, Y)),
         coordAttrsOverride(X, COND, Y)
       )
endmodule

