module MINI-F523-FORMAT-FIX-SYNTAX
  imports BOOL
  imports INT

  syntax Edit ::= dropFormatCall() | removePositionalArguments()
  syntax Bool ::= allArgsUnused(Int, Int) [function]
                | shouldDropFormatCall(Bool, Bool, Bool, Bool, Int, Int) [function]
endmodule

module MINI-F523-FORMAT-FIX
  imports MINI-F523-FORMAT-FIX-SYNTAX

  configuration <k> $PGM:K </k>

  rule allArgsUnused(UNUSED, ARGS) => UNUSED ==Int ARGS

  rule shouldDropFormatCall(KEYWORDSEMPTY, NOFIELDS, LITERALIDENTITY, NONEMPTYUNUSED, UNUSED, ARGS)
    => KEYWORDSEMPTY
       andBool NOFIELDS
       andBool LITERALIDENTITY
       andBool NONEMPTYUNUSED
       andBool allArgsUnused(UNUSED, ARGS)
endmodule
