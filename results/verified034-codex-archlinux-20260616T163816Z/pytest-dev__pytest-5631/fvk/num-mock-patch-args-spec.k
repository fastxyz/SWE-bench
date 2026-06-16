// Constructed FVK artifact for pytest-dev__pytest-5631.
// These claims are intended for later machine checking with K tooling.
// They were not executed in this session.

requires "mini-patchcount.k"

module NUM-MOCK-PATCH-ARGS-SPEC
  imports MINI-PATCHCOUNT

  // SPEC-PROVENANCE:
  // - from_prompt: "patch where 'new' is an array" plus "p.new in sentinels"
  //   causes ValueError => explicit non-sentinel new values must not be treated
  //   as generated mock arguments.
  // - from_code: V1 checks any(p.new is s for s in sentinels), modeled here by
  //   identityIn over object atoms.
  claim
    <k> patchCount(
          ListItem(patch(false, arrayNew)) .List,
          ListItem(defaultUnittest) .List
        ) => 0 </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from public pytest integration tests and function comment: default
  //   patching creates a mock argument that getfuncargnames must ignore.
  // - from default-domain assumption: mock.DEFAULT and unittest.mock.DEFAULT
  //   are singleton sentinels identified by object identity.
  claim
    <k> patchCount(
          ListItem(patch(false, defaultUnittest)) .List,
          ListItem(defaultUnittest) .List
        ) => 1 </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from prior behavior and issue scope: the predicate is a cardinality
  //   filter over all patchings. Non-sentinels do not contribute; sentinels do.
  claim
    <k> patchCount(
          ListItem(patch(false, defaultUnittest))
          ListItem(patch(false, arrayNew))
          ListItem(patch(true, defaultUnittest))
          ListItem(patch(false, otherNew))
          .List,
          ListItem(defaultUnittest) ListItem(defaultMock) .List
        ) => 1 </k>
    [all-path]
endmodule
