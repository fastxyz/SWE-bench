requires "mini-python-where-attrs.k"

module XARRAY-WHERE-ATTRS-SPEC
  imports MINI-PYTHON-WHERE-ATTRS

  // SPEC-PROVENANCE:
  // - E1/E5: scalar x is a documented input class for xr.where.
  // - E2: the legacy lambda attrs[1] fails on a one-entry attrs list.
  // - E4: keep_attrs=True keeps attrs from x; scalar x has no attrs.
  claim <k> selectAttrs(scalar(), ListItem(attrs("cond"))) => emptyAttrs() </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E6: attrs from y are not a fallback when x is scalar.
  claim <k> selectAttrs(scalar(), ListItem(attrs("cond")) ListItem(attrs("y"))) => emptyAttrs() </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: if x participates in this attrs merge, the selected attrs are x attrs.
  claim <k> selectAttrs(xarray(ListItem(attrs("x"))),
                        ListItem(attrs("cond")) ListItem(attrs("x")) ListItem(attrs("y")))
         => attrs("x") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E6: if a merge has no attrs source from x, return empty attrs.
  claim <k> selectAttrs(xarray(ListItem(attrs("x"))),
                        ListItem(attrs("cond")) ListItem(attrs("y")))
         => emptyAttrs() </k>
    [all-path]
endmodule
