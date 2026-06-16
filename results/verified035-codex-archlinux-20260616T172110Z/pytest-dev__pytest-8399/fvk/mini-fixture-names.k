requires "domains.md"

module MINI-FIXTURE-NAMES-SYNTAX
  imports INT
  imports BOOL
  imports STRING
  imports LIST

  syntax HookKind ::= "unittestSetUpClass"
                    | "unittestSetupMethod"
                    | "xunitSetupModule"
                    | "xunitSetupFunction"
                    | "xunitSetupClass"
                    | "xunitSetupMethod"

  syntax FixtureName ::= generatedName(HookKind, String)
  syntax String ::= render(FixtureName) [function]
  syntax Bool ::= isPrivateGenerated(String) [function]
  syntax List ::= showFixtures(Int, List) [function]
endmodule

module MINI-FIXTURE-NAMES
  imports MINI-FIXTURE-NAMES-SYNTAX

  configuration <k> $PGM:K </k>

  rule render(generatedName(unittestSetUpClass, Q))
    => "_unittest_setUpClass_fixture_" +String Q
  rule render(generatedName(unittestSetupMethod, Q))
    => "_unittest_setup_method_fixture_" +String Q
  rule render(generatedName(xunitSetupModule, M))
    => "_xunit_setup_module_fixture_" +String M
  rule render(generatedName(xunitSetupFunction, M))
    => "_xunit_setup_function_fixture_" +String M
  rule render(generatedName(xunitSetupClass, Q))
    => "_xunit_setup_class_fixture_" +String Q
  rule render(generatedName(xunitSetupMethod, Q))
    => "_xunit_setup_method_fixture_" +String Q

  rule isPrivateGenerated(render(generatedName(K, S))) => true

  rule showFixtures(V, .List) => .List
  rule showFixtures(V, ListItem(N) REST)
    => showFixtures(V, REST)
    requires V <=Int 0 andBool isPrivateGenerated(N)
  rule showFixtures(V, ListItem(N) REST)
    => ListItem(N) showFixtures(V, REST)
    requires V >Int 0 orBool notBool isPrivateGenerated(N)
endmodule
