requires "mini-python.k"

module SITEMAP-LASTMOD-SPEC
  imports MINI-PYTHON-SITEMAP

  // SPEC-PROVENANCE:
  // - E6/E7: None is the public "no latest lastmod" value consumed by sitemap index generation.
  claim
    <k> getLatestLastmod => .K </k>
    <lastmod> missing </lastmod>
    <result> _ => none </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: If lastmod is an attribute, get_latest_lastmod returns that attribute.
  claim
    <k> getLatestLastmod => .K </k>
    <lastmod> constant(V:LmValue) </lastmod>
    <result> _ => V </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: Empty callable lastmod is the reported bug case.
  // - E3: max(default=None) is the public hint, so empty callable results produce none.
  claim
    <k> getLatestLastmod => .K </k>
    <lastmod> method(.LmValues) </lastmod>
    <result> _ => none </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: Callable lastmod returns the latest value over all items.
  // - E3: Empty callable result uses the default none.
  // - E8: TypeError remains mapped to none.
  claim
    <k> getLatestLastmod => .K </k>
    <lastmod> method(VS:LmValues) </lastmod>
    <result> _ => fromMax(maxDefault(VS, none)) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: Non-empty comparable callable values produce their maximum.
  claim
    <k> getLatestLastmod => .K </k>
    <lastmod> method(dt(T1:Int) ; dt(T2:Int) ; REST:LmValues) </lastmod>
    <result> _ => fromMax(maxDefault(dt(T1) ; dt(T2) ; REST, none)) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - E8: Existing TypeError recovery is preserved.
  claim
    <k> getLatestLastmod => .K </k>
    <lastmod> method(bad ; REST:LmValues) </lastmod>
    <result> _ => none </result>
    [all-path]
endmodule
