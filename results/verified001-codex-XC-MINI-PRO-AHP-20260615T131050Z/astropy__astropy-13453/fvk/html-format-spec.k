requires "mini-python-html-format.k"

module HTML-FORMAT-SPEC
  imports MINI-PYTHON-HTML-FORMAT
  imports BOOL
  imports INT
  imports STRING
  imports MAP

  // SPEC-PROVENANCE:
  // - from_prompt: "HTML table output to respect the formatting given by the
  //   formats argument" => matching format entries must be applied.
  // - from_code: BaseData._set_col_formats applies self.formats by column name.
  claim
    <k> htmlWrite(col("a", none, 1) .Cols, ("a" |-> "FMT"), false)
      => .Cols ... </k>
    <cols> .Cols => col("a", fmt("FMT"), 1) .Cols </cols>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_intent: columns not named in formats are outside the requested
  //   override and must retain existing formatting behavior.
  // - from_code: _set_col_formats only assigns inside the membership branch.
  claim
    <k> htmlWrite(col("b", none, 1) .Cols, ("a" |-> "FMT"), false)
      => .Cols ... </k>
    <cols> .Cols => col("b", none, 1) .Cols </cols>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: HTML multicolumn output creates temporary split columns.
  // - from_intent: the source column's active format must govern all HTML
  //   data cells belonging to that source column.
  claim
    <k> splitWithSourceFormat(col("C2", fmt("FMT"), 2), 0)
      => col("C2", fmt("FMT"), 1) ... </k>
    [all-path]
endmodule
