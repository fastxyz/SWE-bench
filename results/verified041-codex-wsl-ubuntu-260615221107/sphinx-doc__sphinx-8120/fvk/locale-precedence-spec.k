requires "mini-locale-precedence.k"

module LOCALE-PRECEDENCE-SPEC
  imports MINI-LOCALE-PRECEDENCE
  imports BOOL
  imports LIST

  // SPEC-PROVENANCE:
  // - from_problem: project locale/<language>/LC_MESSAGES/sphinx.mo should
  //   change internal translations such as Fig. %s and Listing %s.
  // - from_hint: intentionally provided sphinx.mo should override system values.
  // - from_code: locale.init gives the first loaded catalog primary status and
  //   attaches later catalogs as fallbacks.
  claim [PROJECT-OVERRIDES]:
    <k> initI18n(ListItem(project(0))) ~> resolve(M:String) => .K </k>
    <order> .List => ListItem(project(0)) ListItem(system) ListItem(package) </order>
    <out> missing => val(project(0), M) </out>
    requires has(project(0), M)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: locale_dirs is a configured search path.
  // - from_code: CatalogRepository yields project locale dirs in config order.
  claim [PROJECT-ORDER]:
    <k> initI18n(ListItem(project(0)) ListItem(project(1))) ~> resolve(M:String) => .K </k>
    <order> .List => ListItem(project(0)) ListItem(project(1)) ListItem(system) ListItem(package) </order>
    <out> missing => val(project(0), M) </out>
    requires has(project(0), M)
     andBool has(project(1), M)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_problem: project overrides may be partial; remaining internal
  //   messages should still be localized.
  // - from_frame: V0 built-in fallback order was system then package.
  claim [BUILTIN-FALLBACK]:
    <k> initI18n(ListItem(project(0))) ~> resolve(M:String) => .K </k>
    <order> .List => ListItem(project(0)) ListItem(system) ListItem(package) </order>
    <out> missing => val(system, M) </out>
    requires notBool has(project(0), M)
     andBool has(system, M)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_problem: missing project entries should fall back to existing
  //   built-in translations.
  // - from_frame: package locale remains the fallback after system.
  claim [PACKAGE-FALLBACK]:
    <k> initI18n(ListItem(project(0))) ~> resolve(M:String) => .K </k>
    <order> .List => ListItem(project(0)) ListItem(system) ListItem(package) </order>
    <out> missing => val(package, M) </out>
    requires notBool has(project(0), M)
     andBool notBool has(system, M)
     andBool has(package, M)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_frame: when no project locale directory is yielded, V1 should keep
  //   V0's built-in order unchanged.
  claim [NO-PROJECT-PRESERVES-OLD-BUILTINS]:
    <k> initI18n(.List) => .K </k>
    <order> .List => ListItem(system) ListItem(package) </order>
    <out> missing </out>
    [all-path]
endmodule
