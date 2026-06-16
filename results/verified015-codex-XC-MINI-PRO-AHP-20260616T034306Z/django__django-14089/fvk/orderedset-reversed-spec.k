requires "mini-python-orderedset.k"

module ORDEREDSET-REVERSED-SPEC
  imports MINI-PYTHON-ORDEREDSET

  // SPEC-PROVENANCE:
  // - from_prompt: "Allow calling reversed() on an OrderedSet" =>
  //   reversed(OrderedSet(xs)) is defined for every valid OrderedSet.
  // - from_prompt: "This would be natural to support given that OrderedSet is ordered" =>
  //   the observed order is the reverse of insertion order.
  // - from_code: OrderedSet stores keys in self.dict = dict.fromkeys(iterable or ()).
  // - from_default_domain: Python dictionaries preserve insertion order and are reversible
  //   in this checkout's supported Python versions (python_requires >= 3.8).
  claim
    <k> list(reversed(OrderedSet(XS:List))) => reverseList(uniqueFirst(XS)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: __iter__ delegates to iter(self.dict), so forward iteration exposes
  //   unique first occurrences in insertion order.
  // - from_prompt: "OrderedSet is ordered" supplies the order axis.
  claim
    <k> list(iter(OrderedSet(XS:List))) => uniqueFirst(XS) </k>
    [all-path]

  // Boundary witness: empty OrderedSet reverses to empty.
  claim
    <k> list(reversed(OrderedSet(.List))) => .List </k>
    [all-path]

  // Duplicate witness: OrderedSet([1, 2, 1]) has insertion order [1, 2],
  // so reversed() observes [2, 1], not [1, 2, 1] reversed.
  claim
    <k> list(reversed(OrderedSet(ListItem(1) ListItem(2) ListItem(1))))
      => ListItem(2) ListItem(1)
    </k>
    [all-path]
endmodule
