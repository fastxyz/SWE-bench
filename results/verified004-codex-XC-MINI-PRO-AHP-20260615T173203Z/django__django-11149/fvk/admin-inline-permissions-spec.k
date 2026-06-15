requires "mini-admin-permissions.k"

module ADMIN-INLINE-PERMISSIONS-SPEC-SYNTAX
  imports MINI-ADMIN-PERMISSIONS-SYNTAX
endmodule

module VERIFICATION
  imports MINI-ADMIN-PERMISSIONS
  imports K-EQUAL
endmodule

module ADMIN-INLINE-PERMISSIONS-SPEC
  imports VERIFICATION

  // Claim: VIEW-OR-CHANGE-CAN-VIEW
  // SPEC-PROVENANCE:
  // - from_prompt: "view only permissions" => read access must not imply write access.
  // - from_code: V1 has_view_permission checks target ['view', 'change'].
  claim
    <k> autoM2MView(TARGET_VIEW:Bool, TARGET_CHANGE:Bool)
      => TARGET_VIEW orBool TARGET_CHANGE
      ... </k>
    [all-path]

  // Claim: WRITE-FOLLOWS-TARGET-CHANGE
  // SPEC-PROVENANCE:
  // - from_prompt: "You can adjust the M2M. You shouldn't be able to." => write must be false without write permission.
  // - from_public_test: target change permission enables add/change/delete for auto-created m2m inlines.
  // - from_code: V1 add/change/delete permission checks target ['change'].
  claim
    <k> autoM2MWrite(TARGET_CHANGE:Bool)
      => TARGET_CHANGE
      ... </k>
    [all-path]

  // Claim: VIEW-ONLY-WRITE-FALSE
  // SPEC-PROVENANCE:
  // - from_prompt: user with only view permission can add/remove; expected no write.
  // - from_code: target view no longer feeds auto-created m2m write checks.
  claim
    <k> autoM2MWrite(false)
      => false
      ... </k>
    [all-path]

  // Claim: VIEW-ONLY-POST-PRESERVES
  // SPEC-PROVENANCE:
  // - from_prompt: submitted add/remove data from a view-only user must not alter the relationship.
  // - from_code: form has_changed/user_deleted paths are guarded by add/change/delete permission hooks.
  claim
    <k> applyInlinePost(autoM2MWrite(false), ORIGINAL:RelState, SUBMITTED:RelState)
      => ORIGINAL
      ... </k>
    [all-path]

  // Claim: TARGET-CHANGE-POST-APPLIES
  // SPEC-PROVENANCE:
  // - from_public_test: target change permission permits add/change/delete for auto-created m2m inlines.
  // - from_code: V1 preserves target-change positive write behavior.
  claim
    <k> applyInlinePost(autoM2MWrite(true), ORIGINAL:RelState, SUBMITTED:RelState)
      => SUBMITTED
      ... </k>
    [all-path]

  // Claim: TARGET-CHANGE-WRITE-TRUE
  // SPEC-PROVENANCE:
  // - from_public_test: "We have change perm on books, so we can add/change/delete inlines."
  // - from_code: V1 maps all three write hooks to target change.
  claim
    <k> autoM2MWrite(true)
      => true
      ... </k>
    [all-path]
endmodule
