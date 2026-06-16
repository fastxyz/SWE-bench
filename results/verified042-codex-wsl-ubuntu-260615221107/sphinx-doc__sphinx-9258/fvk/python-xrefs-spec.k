requires "mini-python-xrefs.k"

module PYTHON-XREF-SPEC
  imports MINI-PYTHON-XREF

  // SPEC-PROVENANCE:
  // - IE-1: problem asks for ":type text: bytes | str".
  // - PO-1: pipe separators must produce two type xrefs and literal pipe text.
  claim
    <k>
      makeXrefs(atom("bytes") ; delim(" | ") ; atom("str") ; .Segments)
      => xref("bytes") ; literal(" | ") ; xref("str") ; .XNodes
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-2: existing docs require "or" separated types to remain linked.
  // - PO-4: existing delimiter behavior is a frame condition.
  claim
    <k>
      makeXrefs(atom("str") ; delim(" or ") ; atom("int") ; delim(" or ") ; atom("None") ; .Segments)
      => xref("str") ; literal(" or ") ; xref("int") ; literal(" or ") ; xref("None") ; .XNodes
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE-2: existing docs require container punctuation to remain linked automatically.
  // - PO-4: bracket, comma, and ellipsis delimiters are preserved.
  claim
    <k>
      makeXrefs(atom("Tuple") ; delim("[") ; atom("str") ; delim(", ") ; delim("...") ; delim("]") ; .Segments)
      => xref("Tuple") ; literal("[") ; xref("str") ; literal(", ") ; literal("...") ; literal("]") ; .XNodes
    </k>
    [all-path]
endmodule
