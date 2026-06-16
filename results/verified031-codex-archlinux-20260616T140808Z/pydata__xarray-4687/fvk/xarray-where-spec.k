requires "mini-xarray-where.k"

module XARRAY-WHERE-SPEC
  imports MINI-XARRAY-WHERE

  // SPEC-PROVENANCE:
  // - E8: where returns elements from x or y depending on cond.
  // - from_code: _where_data_first(x, y, cond) calls duck_array_ops.where(cond, x, y).
  claim [WHERE-VALUE]:
    <k> where(COND, X, Y, KEEP, GLOBAL)
     => result(selectedValue(COND, X, Y), attrsFor(resolveKeep(KEEP, GLOBAL), X, Y, COND))
    </k>

  // SPEC-PROVENANCE:
  // - E2/E3/E7: attrs should be preserved from the data object in xr.where(da == 0, -1, da).
  // - from_code: apply_ufunc sees arguments in x, y, cond order.
  claim [WHERE-KEEP-TRUE-X]:
    <k> where(COND, xobj(VX, A), Y, keepTrue, GLOBAL)
     => result(selectedValue(COND, xobj(VX, A), Y), A)
    </k>

  // SPEC-PROVENANCE:
  // - E2/E3/E7: when x is scalar and y is the attrs-bearing data object, y attrs are preserved.
  claim [WHERE-KEEP-TRUE-Y]:
    <k> where(COND, scalar(VX), xobj(VY, A), keepTrue, GLOBAL)
     => result(selectedValue(COND, scalar(VX), xobj(VY, A)), A)
    </k>

  // SPEC-PROVENANCE:
  // - E4: if x/y have no attrs, cond attrs are the only possible fallback.
  claim [WHERE-KEEP-TRUE-COND]:
    <k> where(xobj(VC, A), scalar(VX), scalar(VY), keepTrue, GLOBAL)
     => result(selectedValue(xobj(VC, A), scalar(VX), scalar(VY)), A)
    </k>

  // SPEC-PROVENANCE:
  // - E6: keep_attrs=False must preserve an explicit drop-attrs choice.
  claim [WHERE-KEEP-FALSE]:
    <k> where(COND, X, Y, keepFalse, GLOBAL)
     => result(selectedValue(COND, X, Y), noAttrs)
    </k>

  // SPEC-PROVENANCE:
  // - E6/E7: None respects the global option; default for this operation preserves attrs.
  claim [WHERE-KEEP-NONE-DEFAULT]:
    <k> where(COND, X, Y, keepNone, globalDefault)
     => result(selectedValue(COND, X, Y), attrsFor(true, X, Y, COND))
    </k>

  // SPEC-PROVENANCE:
  // - E6: global keep_attrs=False remains an opt-out.
  claim [WHERE-KEEP-NONE-GLOBAL-FALSE]:
    <k> where(COND, X, Y, keepNone, globalFalse)
     => result(selectedValue(COND, X, Y), noAttrs)
    </k>
endmodule
