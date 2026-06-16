// Constructed K claims for Paginator.__iter__.
// These claims are not machine-checked in this environment.

requires "mini-python-paginator.k"

module PAGINATOR-ITER-SPEC
  imports MINI-PYTHON-PAGINATOR
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "for page_num in self.page_range: yield self.page(page_num)"
  //   => consuming the iterator yields page(page_num) for each page number.
  // - from_docs: Paginator.page_range is a 1-based range iterator of page numbers.
  //   => pageRange(P) is the traversal source.
  // - from_docs: Paginator.page(number) returns a Page object.
  //   => callPage(P, N) is the yielded observable for page number N.
  // - from_code: V1 uses self.page_range and self.page(page_number).
  //   => implementation matches the intent-derived traversal.
  claim [ITER-PAGES]:
    <k> iterPages(P:Obj) => .K ... </k>
    <pageRange> P |-> RANGE:IntList </pageRange>
    <yielded> .Pages => pagesFor(P, RANGE) </yielded>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "all the pages" and the proposed for/yield loop.
  //   => every page number in the range contributes exactly one yielded page.
  // - from_default_domain: Python for-loops traverse iterable values in iteration order.
  //   => the output order is the range order.
  claim [YIELD-PAGES]:
    <k> yieldPages(P:Obj, RANGE:IntList) => .K ... </k>
    <yielded> OUT:PageList => appendPages(OUT, pagesFor(P, RANGE)) </yielded>
    [all-path]
endmodule
