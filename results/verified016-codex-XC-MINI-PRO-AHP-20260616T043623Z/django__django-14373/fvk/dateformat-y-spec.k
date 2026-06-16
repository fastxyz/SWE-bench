requires "mini-dateformat.k"

module DATEFORMAT-Y-SPEC
  imports MINI-DATEFORMAT

  // SPEC-PROVENANCE:
  // - from_prompt: "Y specifier ... supposed to always return a four-digit
  //   year padded with zeros" => DateFormat.Y() returns a padded year text.
  // - from_docs: "Y Year, 4 digits." => result has visible length 4.
  // - from_default_domain: Python date/datetime years are 1 through 9999.
  // - from_code: V1 body is return '%04d' % self.data.year.
  claim
    <k> DateFormatY(Y:Int) => yearText(4, Y) </k>
    requires (1 <=Int Y) andBool (Y <=Int 9999)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt/docs: format character Y exposes the four-digit year.
  // - from_code: Formatter.format() invokes the formatter method and applies
  //   str(); for a single Y piece, the observable output is DateFormat.Y().
  claim
    <k> FormatterFormatY(Y:Int) => yearText(4, Y) </k>
    requires (1 <=Int Y) andBool (Y <=Int 9999)
    [all-path]
endmodule
