requires "mini-show-versions.k"

module SHOW-VERSIONS-SPEC
  imports MINI-SHOW-VERSIONS
  imports BOOL
  imports STRING
  imports LIST
  imports MAP

  syntax List ::= depsV1() [function]
  syntax List ::= depsPreV1() [function]

  rule depsV1() =>
      ListItem("pip")
      ListItem("setuptools")
      ListItem("sklearn")
      ListItem("numpy")
      ListItem("scipy")
      ListItem("joblib")
      ListItem("Cython")
      ListItem("pandas")
      ListItem("matplotlib")
      .List

  rule depsPreV1() =>
      ListItem("pip")
      ListItem("setuptools")
      ListItem("sklearn")
      ListItem("numpy")
      ListItem("scipy")
      ListItem("Cython")
      ListItem("pandas")
      ListItem("matplotlib")
      .List

  // SPEC-PROVENANCE:
  // - E1/E2/E3: issue requires joblib in show_versions dependencies for
  //   scikit-learn 0.22.
  // - E4: setup.py makes joblib a runtime dependency.
  // - E6: _get_deps_info applies one generic import/version-or-None rule to
  //   every name in the dependency list.
  claim
    <k> getDepsInfo(depsV1()) => M:Map ... </k>
    <installed> INSTALLED:Map </installed>
    <depsInfo> _ => M </depsInfo>
  ensures "joblib" in_keys(M)
   andBool {M["joblib"]} ==K versionOf("joblib", INSTALLED)
  [all-path]

  // SPEC-PROVENANCE:
  // - Frame condition from "Add joblib": existing reported dependencies are
  //   preserved while joblib is added.
  claim
    <k> getDepsInfo(depsV1()) => M:Map ... </k>
    <installed> INSTALLED:Map </installed>
    <depsInfo> _ => M </depsInfo>
  ensures "pip" in_keys(M)
   andBool "setuptools" in_keys(M)
   andBool "sklearn" in_keys(M)
   andBool "numpy" in_keys(M)
   andBool "scipy" in_keys(M)
   andBool "Cython" in_keys(M)
   andBool "pandas" in_keys(M)
   andBool "matplotlib" in_keys(M)
  [all-path]

  // SPEC-PROVENANCE:
  // - E1/E5: user-visible show_versions output must contain the dependency
  //   map entries produced by _get_deps_info().
  claim
    <k> showVersions(depsV1()) => . ... </k>
    <installed> INSTALLED:Map </installed>
    <printedDeps> _ => PRINTED:Map </printedDeps>
  ensures "joblib" in_keys(PRINTED)
   andBool {PRINTED["joblib"]} ==K versionOf("joblib", INSTALLED)
  [all-path]

  // SPEC-PROVENANCE:
  // - Diagnostic only: pre-V1 omitted joblib from the dependency list, which
  //   localizes the reported issue. This is not desired behavior.
  claim
    <k> getDepsInfo(depsPreV1()) => M:Map ... </k>
    <installed> INSTALLED:Map </installed>
    <depsInfo> _ => M </depsInfo>
  ensures notBool "joblib" in_keys(M)
  [all-path]
endmodule
