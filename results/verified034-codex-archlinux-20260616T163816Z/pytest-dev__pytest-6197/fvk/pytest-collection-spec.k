// Abstract claims for pytest-dev__pytest-6197.
// Constructed for FVK documentation; not machine-checked in this workspace.

requires "mini-pytest-collection.k"

module PYTEST-COLLECTION-SPEC
  imports MINI-PYTEST-COLLECTION
  imports SET
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: pytest must not import random __init__.py files under cwd.
  // - from_code: V1 Package.collect no longer calls _mount_obj_if_needed().
  // - finding: F1/F2; proof obligations PO1/PO2.
  claim
    <k> collectPackage(P:Path) => done ... </k>
    <imports> .Set => .Set </imports>
    requires notBool hasModuleDesc(P)
         andBool notBool initMatchesPythonFiles(P)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: package pytestmark in __init__.py applies to child tests.
  // - from_code: V1 Module.collect calls _mount_package_parents() first.
  // - finding: F3; proof obligation PO3.
  claim
    <k> collectModule(M:Path, PS:Set) => done ... </k>
    <imports> .Set => PS SetItem(M) </imports>
    [all-path]
endmodule
