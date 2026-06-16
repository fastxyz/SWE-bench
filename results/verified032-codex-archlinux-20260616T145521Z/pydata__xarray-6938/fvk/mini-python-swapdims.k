requires "domains.md"

module MINI-PYTHON-SWAPDIMS-SYNTAX
  imports INT-SYNTAX
  imports MAP-SYNTAX
  imports K-EQUAL-SYNTAX

  syntax ObjId ::= Int
  syntax DataId ::= Int
  syntax AttrId ::= Int
  syntax EncId ::= Int

  syntax Kind ::= "base" | "index"
  syntax Dims ::= "dims" "(" KList ")"
  syntax VarRec ::= "var" "(" Kind "," Dims "," DataId "," AttrId "," EncId ")"

  syntax Stmt ::= "toIndex" "(" ObjId ")"
                | "copyVar" "(" ObjId ")"
                | "toBase" "(" ObjId ")"
                | "setDims" "(" ObjId "," Dims ")"
                | "swapDimsPromoteV1" "(" ObjId "," Dims ")"
                | "swapDimsPromoteOld" "(" ObjId "," Dims ")"
                | "swapDimsBaseBranch" "(" ObjId "," Dims ")"
  syntax Result ::= "none" | ObjId
endmodule

module MINI-PYTHON-SWAPDIMS
  imports MINI-PYTHON-SWAPDIMS-SYNTAX
  imports INT
  imports MAP
  imports K-EQUAL

  configuration
    <k> $PGM:K </k>
    <heap> .Map </heap>
    <result> none </result>
    <fresh> 1000 </fresh>

  // Abstract object-identity semantics for the relevant xarray fragment.
  // The notation H [ V ] and H [ V <- Rec ] is the standard map lookup/update
  // shape used here for constructed proof obligations; these artifacts were not
  // machine-checked in this benchmark workspace.

  rule <k> toIndex(V) => V ... </k>
       <heap> H </heap>
    requires H [ V ] ==K var(index, DS, D, A, E)

  rule <k> toIndex(V) => N ... </k>
       <heap> H => H [ N <- var(index, DS, D, A, E) ] </heap>
       <fresh> N => N +Int 1 </fresh>
    requires H [ V ] ==K var(base, DS, D, A, E)

  rule <k> copyVar(V) => N ... </k>
       <heap> H => H [ N <- var(K, DS, D, A, E) ] </heap>
       <fresh> N => N +Int 1 </fresh>
    requires H [ V ] ==K var(K, DS, D, A, E)

  rule <k> toBase(V) => N ... </k>
       <heap> H => H [ N <- var(base, DS, D, A, E) ] </heap>
       <fresh> N => N +Int 1 </fresh>
    requires H [ V ] ==K var(K, DS, D, A, E)

  rule <k> setDims(V, NEW) => . ... </k>
       <heap> H => H [ V <- var(K, NEW, D, A, E) ] </heap>
    requires H [ V ] ==K var(K, OLD, D, A, E)

  // V1 promoted branch: var = v.to_index_variable().copy(deep=False); var.dims = dims
  rule <k> swapDimsPromoteV1(V, NEW) => toIndex(V) ~> copyVarResult(NEW) ... </k>

  syntax KItem ::= "copyVarResult" "(" Dims ")"
  rule <k> R:Int ~> copyVarResult(NEW) => copyVar(R) ~> setDimsResult(NEW) ... </k>

  syntax KItem ::= "setDimsResult" "(" Dims ")"
  rule <k> R:Int ~> setDimsResult(NEW) => setDims(R, NEW) ~> finishResult(R) ... </k>

  syntax KItem ::= "finishResult" "(" ObjId ")"
  rule <k> finishResult(R) => . ... </k>
       <result> _ => R </result>

  // Pre-V1 promoted branch, kept only as a bug witness.
  rule <k> swapDimsPromoteOld(V, NEW) => toIndex(V) ~> setDimsResult(NEW) ... </k>

  // Non-promoted branch: var = v.to_base_variable(); var.dims = dims
  rule <k> swapDimsBaseBranch(V, NEW) => toBase(V) ~> setDimsResult(NEW) ... </k>
endmodule
