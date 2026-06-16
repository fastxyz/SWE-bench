requires "mini-sphinx-version.k"

module NEEDS-EXTENSIONS-SPEC
  imports MINI-SPHINX-VERSION

  // Concrete public witness from sphinx-doc__sphinx-9711.
  rule validVersion("0.6.0") => true [simplification]
  rule validVersion("0.10.0") => true [simplification]
  rule versionGE("0.10.0", "0.6.0") => true [simplification]

  // SPEC-PROVENANCE:
  // - E-001/E-003/E-004: needs_extensions and extension metadata use version
  //   strings, so valid strings must be compared by parsed version ordering.
  claim <k> needsSatisfied(REQUIRED:String, LOADED:String) => versionGE(LOADED, REQUIRED) </k>
    requires validVersion(REQUIRED) andBool validVersion(LOADED)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002: sphinx-gallery 0.10.0 must satisfy a 0.6.0 minimum.
  claim <k> needsSatisfied("0.6.0", "0.10.0") => true </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-005/E-006: invalid version strings are outside the documented
  //   version-ordering proof domain; V1 preserves the previous string fallback
  //   to avoid new non-version failures.
  claim <k> needsSatisfied(REQUIRED:String, LOADED:String) => stringGE(LOADED, REQUIRED) </k>
    requires notBool (validVersion(REQUIRED) andBool validVersion(LOADED))
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002: the reported loaded extension must not raise when checked alone.
  claim
    <k> verify(need("sphinx_gallery.gen_gallery", "0.6.0"); .Needs,
               have("sphinx_gallery.gen_gallery", "0.10.0"); .Loaded)
        => normal </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-005: missing extensions warn and do not become version errors.
  claim
    <k> verify(need(NAME:String, REQUIRED:String); REST:Needs, LOADED:Loaded)
        => warned(NAME, verify(REST, LOADED)) </k>
    requires notBool hasExt(LOADED, NAME)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-004/E-005: unknown version is still too weak and raises.
  claim
    <k> verify(need(NAME:String, REQUIRED:String); REST:Needs, LOADED:Loaded)
        => raised(NAME, REQUIRED, "unknown version") </k>
    requires hasExt(LOADED, NAME)
     andBool lookupExt(LOADED, NAME) ==String "unknown version"
    [all-path]

  // SPEC-PROVENANCE:
  // - E-001/E-003: known valid loaded versions older than the requirement
  //   remain rejected.
  claim
    <k> verify(need(NAME:String, REQUIRED:String); REST:Needs, LOADED:Loaded)
        => raised(NAME, REQUIRED, lookupExt(LOADED, NAME)) </k>
    requires hasExt(LOADED, NAME)
     andBool lookupExt(LOADED, NAME) =/=String "unknown version"
     andBool validVersion(REQUIRED)
     andBool validVersion(lookupExt(LOADED, NAME))
     andBool notBool versionGE(lookupExt(LOADED, NAME), REQUIRED)
    [all-path]

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-003: known valid loaded versions equal to or newer than
  //   the requirement do not raise for that entry.
  claim
    <k> verify(need(NAME:String, REQUIRED:String); REST:Needs, LOADED:Loaded)
        => verify(REST, LOADED) </k>
    requires hasExt(LOADED, NAME)
     andBool lookupExt(LOADED, NAME) =/=String "unknown version"
     andBool validVersion(REQUIRED)
     andBool validVersion(lookupExt(LOADED, NAME))
     andBool versionGE(lookupExt(LOADED, NAME), REQUIRED)
    [all-path]
endmodule
