requires "mini-python-message-tags.k"

module MESSAGE-TAGS-SPEC
  imports MINI-PYTHON-MESSAGE-TAGS
  imports K-EQUAL
  imports MAP-SYMBOLIC

  // SPEC-PROVENANCE:
  // - E1/E3: The issue requires a setting_changed receiver to update LEVEL_TAGS.
  // - E5: MESSAGE_TAGS extends and overrides default tags.
  // - E9/F-1: V2 preserves the LEVEL_TAGS mapping object identity.
  claim
    <k> updateLevelTags("MESSAGE_TAGS") => .K </k>
    <settingsTags> S:Map </settingsTags>
    <defaultTags> D:Map </defaultTags>
    <levelTags> T:Map => mergeTags(D, S) </levelTags>
    <levelTagsObject> OID:Int </levelTagsObject>
    [label(update-message-tags), all-path]

  // SPEC-PROVENANCE:
  // - I5: Unrelated setting_changed events must not alter LEVEL_TAGS.
  claim
    <k> updateLevelTags(SETTING:String) => .K </k>
    <levelTags> T:Map => T </levelTags>
    <levelTagsObject> OID:Int </levelTagsObject>
    requires SETTING =/=String "MESSAGE_TAGS"
    [label(ignore-other-setting), all-path]

  // SPEC-PROVENANCE:
  // - E2/E6: Message.level_tag must observe the active MESSAGE_TAGS mapping.
  // - E4/E5: Custom levels are supported and MESSAGE_TAGS extends defaults.
  claim
    <k> updateLevelTags("MESSAGE_TAGS")
         ~> messageLevelTag(L:Int) => .K </k>
    <settingsTags> S:Map </settingsTags>
    <defaultTags> D:Map </defaultTags>
    <levelTags> T:Map => mergeTags(D, S) </levelTags>
    <levelTagsObject> OID:Int </levelTagsObject>
    <result> _ => tagOf(mergeTags(D, S), L) </result>
    [label(message-level-tag-after-update), all-path]

  // SPEC-PROVENANCE:
  // - E6: level_tag is a lookup in the current effective tag map.
  claim
    <k> messageLevelTag(L:Int) => .K </k>
    <levelTags> T:Map </levelTags>
    <result> _ => tagOf(T, L) </result>
    [label(message-level-tag-current-map), all-path]

  // SPEC-PROVENANCE:
  // - E7: override_settings.disable() restores settings before sending the
  //   exit setting_changed signal.
  claim
    <k> updateLevelTags("MESSAGE_TAGS")
         ~> messageLevelTag(L:Int) => .K </k>
    <settingsTags> S0:Map </settingsTags>
    <defaultTags> D:Map </defaultTags>
    <levelTags> T:Map => mergeTags(D, S0) </levelTags>
    <levelTagsObject> OID:Int </levelTagsObject>
    <result> _ => tagOf(mergeTags(D, S0), L) </result>
    [label(restore-after-exit), all-path]
endmodule
