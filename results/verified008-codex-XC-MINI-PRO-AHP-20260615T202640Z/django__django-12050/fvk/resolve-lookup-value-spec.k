requires "mini-python-resolve-lookup.k"

module RESOLVE-LOOKUP-VALUE-SPEC
  imports MINI-PYTHON-RESOLVE-LOOKUP

  // SPEC-PROVENANCE:
  // - from_prompt: "coerces value of type list to tuple" => list inputs must
  //   keep the list constructor after element resolution.
  // - from_prompt: "expected iterable return type should match input iterable
  //   type" => list and tuple categories must be preserved.
  claim [LIST-PRESERVES-CONSTRUCTOR]:
    <k> resolveLookupValue(pyList(VS:Vals), CR:Bool, AJ:Bool, SC:Bool)
      => pyList(resolveLookupValues(VS, CR, AJ, SC)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "expected iterable return type should match input iterable
  //   type" => tuple inputs keep the tuple constructor.
  claim [TUPLE-PRESERVES-CONSTRUCTOR]:
    <k> resolveLookupValue(pyTuple(VS:Vals), CR:Bool, AJ:Bool, SC:Bool)
      => pyTuple(resolveLookupValues(VS, CR, AJ, SC)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: "The items of the iterable may be expressions and therefore
  //   need to be resolved independently." => head is resolved with the same
  //   flags and the tail is resolved recursively, preserving order.
  claim [ELEMENTS-RESOLVE-IN-ORDER]:
    <k> resolveLookupValues((V:Val , VS:Vals), CR:Bool, AJ:Bool, SC:Bool)
      => resolveLookupValue(V, CR, AJ, SC) , resolveLookupValues(VS, CR, AJ, SC) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the empty iterable branch has no elements to resolve and
  //   preserves empty length/order.
  claim [ELEMENTS-EMPTY]:
    <k> resolveLookupValues(.Vals, CR:Bool, AJ:Bool, SC:Bool) => .Vals </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: F expressions receive simple_col in their resolve kwargs.
  claim [F-EXPR-RESOLUTION-FRAME]:
    <k> resolveLookupValue(fexpr(X:Id), CR:Bool, AJ:Bool, SC:Bool)
      => fresolved(X, CR, AJ, SC) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: non-F expressions are resolved with reuse and allow_joins.
  claim [EXPR-RESOLUTION-FRAME]:
    <k> resolveLookupValue(expr(X:Id), CR:Bool, AJ:Bool, SC:Bool)
      => resolved(X, CR, AJ) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: values outside the expression/list/tuple branches are
  //   returned unchanged.
  claim [ATOM-FRAME]:
    <k> resolveLookupValue(atom(X:Id), CR:Bool, AJ:Bool, SC:Bool)
      => atom(X) </k>
    [all-path]
endmodule
