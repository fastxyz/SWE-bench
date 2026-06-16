requires "mini-pytest-modpath.k"

module PYTEST-MODPATH-SPEC
  imports MINI-PYTEST-MODPATH
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: reported headline must preserve "test_boo[..[]".
  // - from_code: parametrized Function.name is a single selected node-name part.
  // - conflicts: legacy replace(".[", "[") would produce "test_boo[.[]".
  claim
    <k> getmodpath(namedNode("test_boo[..[]") ; moduleNode("bug.py") ; .Nodes, true, false)
        => "test_boo[..[]" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the report headline domain is the modpath from reportinfo/location/head_line.
  // - from_code: the intervening report path does not content-normalize the domain string.
  claim
    <k> getmodpath(CHAIN:Nodes, STOP:Bool, INCLUDE:Bool)
        => projectJoin(CHAIN, STOP, INCLUDE) </k>
    [all-path]
endmodule
