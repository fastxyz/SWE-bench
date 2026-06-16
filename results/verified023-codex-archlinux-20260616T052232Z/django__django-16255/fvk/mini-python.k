// FVK mini-Python fragment for django.contrib.sitemaps.Sitemap.get_latest_lastmod.
// Status: constructed, not machine-checked.
//
// This is a property-complete abstraction for the audited defect. It models:
// - missing vs constant vs callable lastmod,
// - finite result lists produced by applying callable lastmod to items,
// - max(result_list, default=None),
// - existing TypeError recovery.

module MINI-PYTHON-SITEMAP-SYNTAX
  imports INT-SYNTAX

  syntax Stmt ::= "getLatestLastmod"

  syntax LmValue ::= "none"
                   | "dt" "(" Int ")"
                   | "bad"

  syntax LmValues ::= ".LmValues"
                    | LmValue ";" LmValues [right]

  syntax Lastmod ::= "missing"
                   | "constant" "(" LmValue ")"
                   | "method" "(" LmValues ")"

  syntax MaxResult ::= "ok" "(" LmValue ")"
                     | "typeError"

  syntax KResult ::= LmValue | Lastmod | MaxResult
endmodule

module MINI-PYTHON-SITEMAP
  imports MINI-PYTHON-SITEMAP-SYNTAX
  imports INT

  configuration
    <k> $PGM:Stmt </k>
    <lastmod> missing </lastmod>
    <result> none </result>

  syntax Int ::= maxInt(Int, Int) [function]
  rule maxInt(I1:Int, I2:Int) => I1 requires I1 >=Int I2
  rule maxInt(I1:Int, I2:Int) => I2 requires I1 <Int I2

  syntax MaxResult ::= maxDefault(LmValues, LmValue) [function]
  rule maxDefault(.LmValues, D:LmValue) => ok(D)
  rule maxDefault(bad ; REST:LmValues, D:LmValue) => typeError
  rule maxDefault(dt(T:Int) ; .LmValues, D:LmValue) => ok(dt(T))
  rule maxDefault(dt(T1:Int) ; dt(T2:Int) ; REST:LmValues, D:LmValue)
    => maxDefault(dt(maxInt(T1, T2)) ; REST, D)
  rule maxDefault(dt(T:Int) ; bad ; REST:LmValues, D:LmValue) => typeError

  syntax LmValue ::= fromMax(MaxResult) [function]
  rule fromMax(ok(V:LmValue)) => V
  rule fromMax(typeError) => none

  rule
    <k> getLatestLastmod => .K </k>
    <lastmod> missing </lastmod>
    <result> _ => none </result>

  rule
    <k> getLatestLastmod => .K </k>
    <lastmod> constant(V:LmValue) </lastmod>
    <result> _ => V </result>

  rule
    <k> getLatestLastmod => .K </k>
    <lastmod> method(VS:LmValues) </lastmod>
    <result> _ => fromMax(maxDefault(VS, none)) </result>
endmodule
