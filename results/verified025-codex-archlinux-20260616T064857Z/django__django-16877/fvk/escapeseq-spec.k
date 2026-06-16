requires "mini-python-template-filters.k"

module ESCAPESEQ-SPEC
  imports MINI-PYTHON-TEMPLATE-FILTERS

  // SPEC-PROVENANCE:
  // - from_prompt: "New template filter `escapeseq`" => public filter behavior.
  // - from_prompt: "each item of some_list is escaped before applying the join operation"
  //   => same-order per-item conditional escaping before join.
  // - from_docs: "`escape` ... only result in one round of escaping" => already-safe
  //   inputs remain safe and are not force-escaped.
  // - from_code: V1 function body is `[conditional_escape(obj) for obj in value]`.
  claim
    <k> escapeseq(L:Items) => escapeSeq(L) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: example `{{ some_list|escapeseq|join:"," }}` with autoescape off.
  // - from_code: `join(..., autoescape=False)` concatenates sequence values directly
  //   and then marks the aggregate safe.
  claim
    <k> joinOff(escapeseq(L:Items), SEP:String)
      => safe(joinSafe(escapeSeq(L), SEP)) </k>
    [all-path]
endmodule
