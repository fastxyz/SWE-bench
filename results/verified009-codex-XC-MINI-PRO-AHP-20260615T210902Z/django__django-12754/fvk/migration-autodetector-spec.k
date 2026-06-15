requires "mini-migration-autodetector.k"

module MIGRATION-AUTODETECTOR-SPEC
  imports MINI-MIGRATION-AUTODETECTOR

  // SPEC-PROVENANCE:
  // - I-001: The public issue requires RemoveField(base.field) before
  //   CreateModel(subclass) when a field is moved from a base to a new
  //   subclass in one migration.
  // - I-002: The public hint identifies (base_app_label, base_model_name,
  //   field_name, False) as the dependency representation.
  //
  // Claim schema PO-001: dependency generation for a new subclass.
  claim
    <k> generateDeps(MApp, M, BApp, BModel, BModelLower, F) => done </k>
    requires baseOf(M, BApp, BModel, BModelLower)
     andBool localField(M, F)
     andBool removedField(BApp, BModelLower, F)
    ensures autoDep(create(MApp, M), depRemove(BApp, BModel, F))

  // Claim schema PO-003: same-app sorting places the matched remove before
  // create.
  claim
    <k> sortSameApp(create(App, M), remove(App, BModel, F), depRemove(App, BModel, F)) => done </k>
    requires autoDep(create(App, M), depRemove(App, BModel, F))
     andBool generated(remove(App, BModel, F))
     andBool matches(remove(App, BModel, F), depRemove(App, BModel, F))
    ensures before(remove(App, BModel, F), create(App, M))

  // Claim schema PO-004: cross-app splitting records a migration dependency.
  claim
    <k> splitCrossApp(create(ChildApp, M), remove(BaseApp, BModel, F), depRemove(BaseApp, BModel, F)) => done </k>
    requires autoDep(create(ChildApp, M), depRemove(BaseApp, BModel, F))
     andBool generated(remove(BaseApp, BModel, F))
    ensures migrationDependsOn(create(ChildApp, M), remove(BaseApp, BModel, F))

  // SPEC-PROVENANCE:
  // - I-003: Multiple subclasses depending on the same removed base field must
  //   not duplicate RemoveField.
  //
  // Claim schema PO-005.
  claim
    <k> generateRemoved(BApp, BModel, F) => done </k>
    requires removedField(BApp, BModel, F)
    ensures countRemove(BApp, BModel, F, 1)
endmodule
