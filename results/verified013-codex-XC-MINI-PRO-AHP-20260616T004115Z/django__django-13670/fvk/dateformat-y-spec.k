requires "mini-python-dateformat.k"

module DATEFORMAT-Y-SPEC
  imports MINI-PYTHON-DATEFORMAT
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "dateformat.y() doesn't support years < 1000" =>
  //   y must be correct for small years.
  // - from_prompt: year 123 should produce 23 like Python strftime("%y")
  //   and PHP date("y") => the result is the last two year digits.
  // - from_docs: "y Year, 2 digits." => the output has exactly two digits.
  // - from_public_test: year 1979 with y returns 79 => ordinary years are
  //   preserved.
  // - from_code: V1 computes '%02d' % (year % 100) => modeled as
  //   dateformatY(Y) = pad2(Y % 100).
  claim [Y-TWO-DIGIT]:
    <k> dateformatY(Y:Int)
      => digits2((Y modInt 100) /Int 10, (Y modInt 100) modInt 10)
    </k>
    requires 1 <=Int Y andBool Y <=Int 9999
    [all-path]
endmodule
