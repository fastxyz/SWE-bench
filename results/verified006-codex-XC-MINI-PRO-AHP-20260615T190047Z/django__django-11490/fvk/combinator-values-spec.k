requires "mini-django-query.k"

module COMBINATOR-VALUES-SPEC
  imports MINI-DJANGO-QUERY

  // SPEC-PROVENANCE:
  // - from_prompt: "Composed queries cannot change the list of columns when
  //   values()/values_list() is evaluated multiple times" => repeated outer
  //   selections are independent.
  // - from_code: V1 constructs each child compiler from query.clone().
  // - conflicts: pre-fix compileOld(nameOrder) leaves the original child with
  //   nameOrder, blocking a later compileOld(order) from selecting only order.
  claim <k> compileV1(nameOrder) ~> compileV1(order) => done ~> done </k>
        <orig> q(.Fields, .Fields) => q(.Fields, .Fields) </orig>
        <compiled> _ => q(order, order) </compiled>

  // SPEC-PROVENANCE:
  // - from_code/comment: Child branches without values_select must receive
  //   the outer selected columns during the current compilation.
  claim <k> compileV1(order) => done </k>
        <orig> q(.Fields, .Fields) => q(.Fields, .Fields) </orig>
        <compiled> _ => q(order, order) </compiled>

  // SPEC-PROVENANCE:
  // - from_code/comment: A child query that already has values_select is not
  //   overridden by the outer selected field list.
  claim <k> compileV1(order) => done </k>
        <orig> q(explicit, explicit) => q(explicit, explicit) </orig>
        <compiled> _ => q(explicit, explicit) </compiled>
endmodule
