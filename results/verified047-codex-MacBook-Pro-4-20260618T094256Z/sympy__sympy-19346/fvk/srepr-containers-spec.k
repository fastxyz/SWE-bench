requires "mini-python.k"

module SREPR-CONTAINERS-SPEC
  imports MINI-PYTHON

  // SPEC-PROVENANCE:
  // - from_prompt: "srepr prints the element in list and tuple correctly" => preserve recursive list behavior.
  // - from_code: ReprPrinter._print_list calls reprify on every element.
  // - conflicts: none.
  claim
    <k> srepr(PyList(Sym("x") :: Sym("y") :: .Vals))
      => "[Symbol('x'), Symbol('y')]" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "srepr prints the element in list and tuple correctly" => preserve recursive tuple behavior.
  // - from_code: ReprPrinter._print_tuple recursively prints every element and preserves tuple punctuation.
  // - conflicts: none.
  claim
    <k> srepr(PyTuple(Sym("x") :: Sym("y") :: .Vals))
      => "(Symbol('x'), Symbol('y'))" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "srepr prints the elements in dict and set wrong" with "{x, y}" => set members must use srepr form.
  // - from_default_domain: unordered Python sets may be rendered in deterministic printer order.
  // - from_code: V1 _print_set sorts with default_sort_key and calls reprify on every member.
  // - conflicts: pre-fix display "{x, y}" is SUSPECT legacy behavior.
  claim
    <k> srepr(PySet(Sym("x") :: Sym("y") :: .Vals))
      => "{Symbol('x'), Symbol('y')}" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: same set obligation as above.
  // - from_default_domain: deterministic printer ordering should not depend on hash/insertion order for sets.
  // - from_code: sortVals abstracts default_sort_key; concrete x/y order is x before y.
  // - conflicts: none.
  claim
    <k> srepr(PySet(Sym("y") :: Sym("x") :: .Vals))
      => "{Symbol('x'), Symbol('y')}" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "srepr prints the elements in dict and set wrong" with "{x: y}" => dict keys and values must use srepr form.
  // - from_code: V1 _print_dict sorts keys and calls _print on both key and value.
  // - conflicts: pre-fix display "{x: y}" is SUSPECT legacy behavior.
  claim
    <k> srepr(PyDict(pair(Sym("x"), Sym("y")) :: .Pairs))
      => "{Symbol('x'): Symbol('y')}" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the dict/set defect is recursive element printing, not only the concrete x/y atoms.
  // - from_code: _print_set delegates every sorted member to reprify/doprint.
  // - conflicts: none.
  claim
    <k> srepr(PySet(V:Val :: VS:Vals))
      => "{" +String reprSeq(sortVals(V :: VS)) +String "}" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the dict defect covers both keys and values.
  // - from_code: _print_dict formats each sorted key as self._print(key) and value as self._print(expr[key]).
  // - conflicts: none.
  claim
    <k> srepr(PyDict(PS:Pairs))
      => "{" +String reprPairs(sortPairs(PS)) +String "}" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: empty Python set must keep Python's non-literal spelling to avoid dict ambiguity.
  // - from_default_domain: Python uses set() for the empty set and {} for the empty dict.
  // - conflicts: none.
  claim
    <k> srepr(PySet(.Vals)) => "set()" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: _print_dict on an empty mapping joins no items and returns "{}".
  // - from_default_domain: Python uses {} for the empty dict.
  // - conflicts: none.
  claim
    <k> srepr(PyDict(.Pairs)) => "{}" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: set-like containers should not retain the same recursive-printing defect.
  // - from_code: V1 _print_frozenset delegates nonempty members through _print_set and preserves frozenset(...).
  // - conflicts: none.
  claim
    <k> srepr(PyFrozenSet(Sym("x") :: .Vals))
      => "frozenset({Symbol('x')})" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: V1 _print_Dict wraps the recursive dict literal in Dict(...), preserving eval-friendly SymPy Dict type.
  // - from_public_test_convention: test_repr.py documents eval(srepr(expr)) == expr as the expected srepr contract.
  // - conflicts: none.
  claim
    <k> srepr(SymDict(pair(Sym("x"), Sym("y")) :: .Pairs))
      => "Dict({Symbol('x'): Symbol('y')})" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: reprify recursively prints the head and recurs on the tail.
  // - from_prompt: list/tuple examples establish recursive element printing as the intended family behavior.
  // - conflicts: none.
  claim
    <k> reprSeq(V1:Val :: V2:Val :: VS:Vals)
      => reprOf(V1) +String ", " +String reprSeq(V2 :: VS) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: _print_dict's loop recursively prints every key/value pair.
  // - from_prompt: dict example establishes recursive printing for both sides of ":".
  // - conflicts: none.
  claim
    <k> reprPairs(pair(K:Val, V:Val) :: P2:Pair :: PS:Pairs)
      => reprOf(K) +String ": " +String reprOf(V) +String ", " +String reprPairs(P2 :: PS) ... </k>
    [all-path]
endmodule
