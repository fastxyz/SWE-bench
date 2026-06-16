requires "mini-latex-inline.k"

module LATEX-INLINE-CODE-SPEC
  imports MINI-LATEX-INLINE

  // SPEC-PROVENANCE:
  // - from_prompt: "For LaTeX output, a space character is inserted at start
  //   and end of the inline code." => the rendered visible inline code must
  //   not gain leading or trailing spaces from formatter wrapper newlines.
  // - from_prompt: "mark-up should be: \sphinxupquote{% ... pass% }}"
  //   => TeX comments are an acceptable way to hide both boundary newlines.
  // - from_code: visit_literal() reaches this path only for literal nodes
  //   whose classes include "code" and whose language option is present.
  claim
    <k> RenderThenVisible(beginVerbatim(Body:String)) => Body </k>
    [all-path]

  // Regression witness for the legacy behavior described by the issue.
  claim
    <k> TeXVisible(sphinxRaw(Body:String))
      => " " +String Body +String " " </k>
    [all-path]
endmodule
