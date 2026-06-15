requires "mini-django-ordering.k"

module DJANGO-ORDERING-SPEC
  imports MINI-DJANGO-ORDERING

  // SPEC-PROVENANCE:
  // - E1/E2: expression ordering items in related Meta.ordering must not
  //   reach get_order_dir(), which is string-only.
  claim
    <k> findOrderingName(exprItem(E:Expr), C:Context, D:Dir)
        => ordering(makeOrder(resolveExpr(E, C), D), false) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E6/E8: F() leaves inside expressions must resolve relative to the
  //   current related opts/alias context.
  claim
    <k> resolveExpr(f(P:Path), C:Context)
        => col(P, setupJoin(P, C)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E5: non-OrderBy expressions such as Lower('name') are wrapped in
  //   ascending OrderBy when no enclosing descending order reverses them.
  claim
    <k> findOrderingName(exprItem(lower(f(P:Path))), C:Context, asc)
        => ordering(orderby(lower(col(P, setupJoin(P, C))), asc), false) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: descending relation ordering reverses the related expression's
  //   ordering direction.
  claim
    <k> findOrderingName(exprItem(orderby(f(P:Path), asc)), C:Context, desc)
        => ordering(orderby(col(P, setupJoin(P, C)), desc), false) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I5: non-expression strings remain on the existing string path.
  claim
    <k> findOrderingName(strItem(S:String), C:Context, D:Dir)
        => stringPathResult ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E9/F2: non-source child nodes are framed unchanged rather than copied
  //   as expression trees.
  claim
    <k> resolveExpr(foreignNode, C:Context) => foreignNode ... </k>
    [all-path]
endmodule
