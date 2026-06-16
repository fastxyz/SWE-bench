requires "mini-java-segmentinfos.k"

module SEGMENTINFOS-REPLACE-SPEC
  imports MINI-JAVA-SEGMENTINFOS

  // SPEC-PROVENANCE:
  // - from_prompt: "replace method ... doesn't set userData with the new user data from other"
  //   => after replace, receiver.userData equals other.userData.
  // - from_prompt: provided fix adds "userData = other.userData"
  //   => direct assignment is an allowed implementation of the obligation.
  // - from_code: replace calls rollbackSegmentInfos(other.asList()) and assigns lastGeneration
  //   => receiver segments and lastGeneration follow other.
  // - from_code: method comment says replace keeps generation, version, counter
  //   => frame condition for those fields.
  // - from_default_domain: package-private method is specified for non-null SegmentInfos other.
  claim
    <k>
      replace(
        si(SELF_SEGS:SegmentList, SELF_LAST:Int, SELF_USER:UserData,
           SELF_GEN:Int, SELF_VER:Int, SELF_COUNTER:Int),
        si(OTHER_SEGS:SegmentList, OTHER_LAST:Int, OTHER_USER:UserData,
           OTHER_GEN:Int, OTHER_VER:Int, OTHER_COUNTER:Int))
      =>
        si(OTHER_SEGS, OTHER_LAST, OTHER_USER, SELF_GEN, SELF_VER, SELF_COUNTER)
    </k>
    [all-path]
endmodule
