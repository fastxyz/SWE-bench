module MINI-EVALF-SYNTAX
  imports INT-SYNTAX

  syntax Part ::= "zero" | "num" | "sym"
  syntax Val ::= "noneVal" | "mpfVal"
  syntax Prec ::= "nonePrec" | "somePrec"
  syntax Outcome ::= "tuple" "(" Val "," Val "," Prec "," Prec ")"
                   | "notImplemented"
  syntax Pgm ::= "fallback" "(" Part "," Part ")"
               | "finishRe" "(" Val "," Prec "," Part ")"

  syntax KResult ::= Outcome
endmodule

module MINI-EVALF
  imports MINI-EVALF-SYNTAX

  configuration <k> $PGM:Pgm </k>

  // Abstracts the changed fallback in sympy/core/evalf.py.
  // Part values mean:
  // - zero: component is exactly zero and represented internally as None.
  // - num: component is numeric and convertible to an mpf tuple.
  // - sym: component remains symbolic/non-numeric after _eval_evalf.
  rule <k> fallback(zero, IM) => finishRe(noneVal, nonePrec, IM) </k>
  rule <k> fallback(num, IM)  => finishRe(mpfVal, somePrec, IM) </k>
  rule <k> fallback(sym, IM)  => notImplemented </k>

  rule <k> finishRe(RE, REP, zero) => tuple(RE, noneVal, REP, nonePrec) </k>
  rule <k> finishRe(RE, REP, num)  => tuple(RE, mpfVal, REP, somePrec) </k>
  rule <k> finishRe(RE, REP, sym)  => notImplemented </k>
endmodule
