requires "mini-xarray.k"

module XARRAY-WHERE-SPEC
  imports MINI-XARRAY

  // SPEC-PROVENANCE:
  // - problem: "Coordinate attributes should be preserved." => coord attrs are
  //   selected from coordinate variables, not data attrs.
  // - docstring: "If True, keep the attrs of `x`." => top/data attrs winner is X.
  // - public hint: scalar X must not select attrs[1] from Y.
  claim
    <k> whereKeepAttrsTrue(COND:Obj, X:Obj, Y:Obj)
     => result(
          whereValue(COND, X, Y),
          attrsOf(X),
          dataAttrsFromX(X, resultDataVars(X, COND, Y)),
          coordAttrsOverride(X, COND, Y)
        )
    </k>
endmodule

