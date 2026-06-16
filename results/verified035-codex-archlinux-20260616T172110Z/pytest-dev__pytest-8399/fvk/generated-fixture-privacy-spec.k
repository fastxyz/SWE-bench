requires "mini-fixture-names.k"

module GENERATED-FIXTURE-PRIVACY-SPEC
  imports MINI-FIXTURE-NAMES

  // SPEC-PROVENANCE:
  // - E1/E2: unittest generated fixture names must start with an underscore.
  // - E3: underscore names are hidden from non-verbose fixture listing.
  claim <k> render(generatedName(unittestSetUpClass, Q:String))
        => "_unittest_setUpClass_fixture_" +String Q ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: cover the other generated unittest setup fixture emitted by the same helper.
  claim <k> render(generatedName(unittestSetupMethod, Q:String))
        => "_unittest_setup_method_fixture_" +String Q ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E5: xunit generated fixtures are part of the affected family.
  claim <k> render(generatedName(xunitSetupModule, M:String))
        => "_xunit_setup_module_fixture_" +String M ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E5: xunit generated fixtures are part of the affected family.
  claim <k> render(generatedName(xunitSetupFunction, M:String))
        => "_xunit_setup_function_fixture_" +String M ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: the issue hint reports xunit setup_class fixture visibility.
  // - E5: the fix must cover all generated fixtures.
  claim <k> render(generatedName(xunitSetupClass, Q:String))
        => "_xunit_setup_class_fixture_" +String Q ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: cover the method-level xunit generated fixture sibling.
  claim <k> render(generatedName(xunitSetupMethod, Q:String))
        => "_xunit_setup_method_fixture_" +String Q ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E6: non-verbose fixture listing skips underscore-prefixed argnames.
  claim <k> showFixtures(0,
             ListItem(render(generatedName(unittestSetUpClass, Q:String)))
             ListItem(render(generatedName(unittestSetupMethod, Q:String)))
             ListItem(render(generatedName(xunitSetupModule, M:String)))
             ListItem(render(generatedName(xunitSetupFunction, M:String)))
             ListItem(render(generatedName(xunitSetupClass, Q:String)))
             ListItem(render(generatedName(xunitSetupMethod, Q:String)))
             .List)
        => .List ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/I4: verbose listing may still expose private fixtures.
  claim <k> showFixtures(1,
             ListItem(render(generatedName(xunitSetupClass, Q:String)))
             .List)
        => ListItem("_xunit_setup_class_fixture_" +String Q) .List ... </k>
    [all-path]
endmodule
