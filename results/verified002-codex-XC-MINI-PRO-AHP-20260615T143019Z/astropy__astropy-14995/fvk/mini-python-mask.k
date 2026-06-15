requires "domains.md"

module MINI-PYTHON-MASK-SYNTAX
  imports INT-SYNTAX

  syntax Mask ::= "NoMask"
                | "Present" "(" Int ")"
                | "Copy" "(" Mask ")"
                | "Combined" "(" Mask "," Mask ")"

  syntax Operand ::= "AbsentOperand"
                   | "Operand" "(" Mask ")"

  syntax HandleMask ::= "NoHandle"
                      | "CallableMask"

  syntax Exp ::= "arithMask" "(" Mask "," Operand "," HandleMask ")"
               | "binaryCallableMask" "(" Mask "," Mask ")"
endmodule

module MINI-PYTHON-MASK
  imports MINI-PYTHON-MASK-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  rule <k> arithMask(SM:Mask, OP:Operand, NoHandle) => NoMask ... </k>

  rule <k> arithMask(NoMask, AbsentOperand, CallableMask) => NoMask ... </k>
  rule <k> arithMask(NoMask, Operand(NoMask), CallableMask) => NoMask ... </k>

  rule <k> arithMask(NoMask, Operand(OM:Mask), CallableMask) => Copy(OM) ... </k>
    requires OM =/=K NoMask

  rule <k> arithMask(SM:Mask, AbsentOperand, CallableMask) => Copy(SM) ... </k>
    requires SM =/=K NoMask

  rule <k> arithMask(SM:Mask, Operand(NoMask), CallableMask) => Copy(SM) ... </k>
    requires SM =/=K NoMask

  rule <k> arithMask(SM:Mask, Operand(OM:Mask), CallableMask) => Combined(SM, OM) ... </k>
    requires SM =/=K NoMask andBool OM =/=K NoMask

  rule <k> binaryCallableMask(SM:Mask, OM:Mask) => arithMask(SM, Operand(OM), CallableMask) ... </k>
endmodule
