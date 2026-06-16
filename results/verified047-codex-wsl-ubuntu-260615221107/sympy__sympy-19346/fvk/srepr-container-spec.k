requires "mini-srepr.k"

module SREPR-CONTAINER-SPEC
  imports MINI-SREPR

  // SPEC-PROVENANCE:
  // - from_prompt: "srepr prints the element in list and tuple correctly" =>
  //   container elements should be rendered through srepr, not normal str.
  // - from_prompt: "srepr prints the elements in dict and set wrong" with
  //   observed "{x, y}" and "{x: y}" => dict/set built-ins are in domain.
  // - from_docs: "eval(srepr(expr)) == expr" => emitted form must remain a
  //   valid evaluable Python container representation.
  // - from_code: Printer dispatch uses _print_<class name>; built-in dict
  //   therefore reaches _print_dict and built-in set reaches _print_set.
  claim <k> srepr(dict(PS:Pairs)) => dictText(sreprPairs(sortPairs(PS))) </k>
    requires hasNoDuplicateKeys(PS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: built-in set example "{x, y}" must recursively print both
  //   elements as srepr values.
  // - from_default_domain: the empty set cannot use "{}" because that is a
  //   dict literal in Python.
  // - from_code: _print_set uses default_sort_key before reprifying elements.
  claim <k> srepr(set(.Objs)) => emptySetText() </k>
    [all-path]

  claim <k> srepr(set(OS:Objs)) => setText(sreprObjs(sortObjs(OS))) </k>
    requires isEmptyObjs(OS) ==Bool false
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code and sibling printers: frozenset is handled with set as the same
  //   built-in unordered-container family.
  // - from_docs: output remains evaluable as a frozenset construction.
  claim <k> srepr(frozenset(.Objs)) => frozensetText(emptySetText()) </k>
    [all-path]

  claim <k> srepr(frozenset(OS:Objs)) => frozensetText(setText(sreprObjs(sortObjs(OS)))) </k>
    requires isEmptyObjs(OS) ==Bool false
    [all-path]
endmodule
