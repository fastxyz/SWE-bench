module MINI-XARRAY-WHERE-SYNTAX
  imports INT
  imports BOOL

  syntax Attrs ::= noAttrs | attrs(Int)
  syntax Obj ::= scalar(Int) | xobj(Int, Attrs)
  syntax Keep ::= keepTrue | keepFalse | keepNone
  syntax GlobalKeep ::= globalDefault | globalTrue | globalFalse
  syntax Result ::= result(Int, Attrs)
  syntax Exp ::= where(Obj, Obj, Obj, Keep, GlobalKeep)

  syntax Bool ::= resolveKeep(Keep, GlobalKeep) [function]
  syntax Attrs ::= attrsFor(Bool, Obj, Obj, Obj) [function]
  syntax Int ::= selectedValue(Obj, Obj, Obj) [function]
endmodule

module MINI-XARRAY-WHERE
  imports MINI-XARRAY-WHERE-SYNTAX

  configuration <k> $PGM:Exp </k>

  // Abstract value semantics: selectedValue(COND, X, Y) represents
  // duck_array_ops.where(COND, X, Y). The proof is about preserving this call
  // shape while changing metadata flow.
  rule <k> where(COND, X, Y, KEEP, GLOBAL)
        => result(selectedValue(COND, X, Y), attrsFor(resolveKeep(KEEP, GLOBAL), X, Y, COND))
       </k>

  rule resolveKeep(keepTrue,  GLOBAL) => true
  rule resolveKeep(keepFalse, GLOBAL) => false
  rule resolveKeep(keepNone,  globalTrue) => true
  rule resolveKeep(keepNone,  globalFalse) => false
  rule resolveKeep(keepNone,  globalDefault) => true

  rule attrsFor(false, X, Y, COND) => noAttrs
  rule attrsFor(true, xobj(VX, A), Y, COND) => A
  rule attrsFor(true, scalar(VX), xobj(VY, A), COND) => A
  rule attrsFor(true, scalar(VX), scalar(VY), xobj(VC, A)) => A
  rule attrsFor(true, scalar(VX), scalar(VY), scalar(VC)) => noAttrs
endmodule
