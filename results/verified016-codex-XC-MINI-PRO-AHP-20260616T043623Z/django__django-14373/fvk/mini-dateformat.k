module MINI-DATEFORMAT-SYNTAX
  imports INT-SYNTAX

  syntax YearText ::= yearText(Int, Int)
  syntax Exp ::= "DateFormatY" "(" Int ")"
               | "FormatterFormatY" "(" Int ")"
               | "pad4" "(" Int ")"
  syntax KResult ::= YearText
endmodule

module MINI-DATEFORMAT
  imports MINI-DATEFORMAT-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // Model of V1:
  //   def Y(self):
  //       return '%04d' % self.data.year
  rule <k> DateFormatY(Y:Int) => pad4(Y) ... </k>

  // Property-complete abstraction of Python's '%04d' % year for the date-year
  // domain. yearText(LEN, VALUE) preserves the visible length axis that
  // distinguishes the pre-V1 failure yearText(2, 42) from yearText(4, 42).
  rule <k> pad4(Y:Int) => yearText(4, Y) ... </k>
    requires (1 <=Int Y) andBool (Y <=Int 9999)

  // Model of Formatter.format() on the single-character "Y" path:
  // getattr(self, "Y")(), then str() of the formatter result.
  rule <k> FormatterFormatY(Y:Int) => DateFormatY(Y) ... </k>
endmodule
