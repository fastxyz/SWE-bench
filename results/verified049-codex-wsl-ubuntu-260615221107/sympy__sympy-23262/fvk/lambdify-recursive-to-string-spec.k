requires "mini-python.k"

module LAMBDIFY-STRINGIFY-SPEC
  imports LAMBDIFY-STRINGIFY
  imports STRING
  imports INT

  // CLAIM: TUPLE-SINGLETON
  // SPEC-PROVENANCE:
  // - from_prompt: "missing comma after `1` that causes an integer to be returned instead of a tuple"
  //   => a native singleton tuple must render with a trailing comma.
  // - from_default_domain: Python singleton tuple syntax is `(<element>,)`.
  // - from_code: V1 handles len(arg) == 1 before the generic tuple join.
  claim
    <k> render(pyTuple(cons(E:Node, emptyNodes())))
     => "(" +String render(E) +String ",)" </k>
    [all-path]

  // CLAIM: RETURN-SINGLETON-TUPLE
  // SPEC-PROVENANCE:
  // - from_prompt: `inspect.getsource(lambdify([], tuple([1])))` should show
  //   `return (1,)`.
  // - from_code: `_EvaluatorPrinter.doprint` appends `return {str_expr}` after
  //   `_recursive_to_string`.
  claim
    <k> returnLine(pyTuple(cons(E:Node, emptyNodes())))
     => "return " +String "(" +String render(E) +String ",)" </k>
    [all-path]

  // CLAIM: TUPLE-EMPTY
  // SPEC-PROVENANCE:
  // - from_intent_frame: preserve ordinary empty tuple literal rendering.
  claim
    <k> render(pyTuple(emptyNodes())) => "()" </k>
    [all-path]

  // CLAIM: TUPLE-MULTI
  // SPEC-PROVENANCE:
  // - from_prompt: tuples with two or more elements already generated
  //   `return (1, 2)`, which the issue states is expected.
  // - from_code: V1 leaves the generic tuple join path unchanged for length >= 2.
  claim
    <k> render(pyTuple(cons(E1:Node, cons(E2:Node, REST:Nodes))))
     => "(" +String renderNodes(cons(E1, cons(E2, REST))) +String ")" </k>
    [all-path]

  // CLAIM: LIST-FRAME
  // SPEC-PROVENANCE:
  // - from_source_docstring: `_recursive_to_string` handles Python lists as
  //   non-SymPy containers.
  // - from_intent_frame: V1 must not change list rendering.
  claim
    <k> render(pyList(NS:Nodes))
     => "[" +String renderNodes(NS) +String "]" </k>
    [all-path]

  // CLAIM: LEAF-DELEGATION
  // SPEC-PROVENANCE:
  // - from_source_docstring: only SymPy/matrix objects should be passed to the
  //   selected printer; raw strings pass through unchanged.
  claim
    <k> render(atom(S:String)) => S </k>
    [all-path]
endmodule
