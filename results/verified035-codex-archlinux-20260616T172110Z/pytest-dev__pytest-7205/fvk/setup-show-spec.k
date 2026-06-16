requires "mini-pytest-setup-show.k"

module SETUP-SHOW-SPEC
  imports MINI-PYTEST-SETUP-SHOW

  // SPEC-PROVENANCE:
  // - from_prompt: "BytesWarning when using --setup-show with bytes parameter"
  //   => raw bytes params must not reach bytesWarning.
  // - from_prompt: "Shouldn't that be using saferepr or something rather than
  //   (implicitly) str()?" => raw params are represented with saferepr.
  // - from_hint: "Probably with a shorter maxsize than the default as well"
  //   => use the bounded safeRepr42 abstraction.
  // - from_code: V2 caches saferepr(request.param, maxsize=42) in the no-ids
  //   branch before _show_fixture_action writes the cached string.
  claim <k> rawParam(bytesParam(B:String)) => safeRepr42(bytesParam(B)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: same bytes-param obligation as above.
  // - from_code: _show_fixture_action writes a cached display string, not the
  //   original parameter object.
  claim <k> writeCached(safeRepr42(bytesParam(B:String)))
           => ok(bracket(safeRepr42(bytesParam(B))))
        </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: raw fixture params use saferepr; fixture ids are display ids,
  //   not raw params.
  // - from_public_test: existing setup-only tests use ids=["spam", "ham"] as
  //   user-facing labels; this supports preserving plain string ids.
  // - from_code: _format_fixture_id returns str ids unchanged.
  claim <k> fixtureId(idStr(S:String)) => display(S) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: avoid implicit str() on bytes-like display values.
  // - from_code: _format_fixture_id routes non-string ids through saferepr.
  claim <k> fixtureId(idBytes(B:String)) => safeRepr42(bytesParam(B)) </k>
    [all-path]
endmodule
