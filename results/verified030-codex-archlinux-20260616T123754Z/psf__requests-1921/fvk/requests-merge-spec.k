requires "mini-requests-merge.k"

module REQUESTS-MERGE-SPEC
  imports MINI-REQUESTS-MERGE
  imports MAP
  imports STRING
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: request-level and session-level header None values are
  //   deletion sentinels.
  // - from_code: merge_setting copies session mapping, updates with request
  //   mapping, then deletes final None-valued keys in V1.
  claim [C-MERGE-MAPPING]:
    <k> mergeSetting(mapping(REQ:Map), mapping(SES:Map))
      => mapping(filterNone(overlay(SES, REQ))) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "session.headers['Accept-Encoding'] = None" should mean
  //   "Do not send Accept-Encoding".
  // - from_code: Request(headers=None) is normalized to an empty mapping before
  //   Session.prepare_request calls merge_setting.
  claim [C-SESSION-NONE]:
    <k> mergeSetting(mapping(.Map),
          mapping(("accept-encoding" |-> noneVal) REST:Map))
      => mapping(filterNone(REST)) ... </k>
    requires notBool keyIn("accept-encoding", REST)
    ensures notBool keyIn("accept-encoding", filterNone(REST))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: request headers {'FOO': None} remove session header
  //   'foo' case-insensitively.
  claim [C-REQUEST-NONE]:
    <k> mergeSetting(
          mapping(("foo" |-> noneVal) .Map),
          mapping(("foo" |-> value("bar")) .Map))
      => mapping(.Map) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/docstring: request setting is explicit and overrides session
  //   setting before final None deletion is applied.
  claim [C-REQUEST-OVERRIDE]:
    <k> mergeSetting(
          mapping(("accept-encoding" |-> value("identity")) .Map),
          mapping(("accept-encoding" |-> noneVal) .Map))
      => mapping(("accept-encoding" |-> value("identity")) .Map) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/docstring: non-dictionary settings bypass merging and the
  //   request setting wins.
  claim [C-NONMAPPING-FRAME]:
    <k> mergeSetting(scalar(value("request")),
          mapping(("accept" |-> value("*/*")) .Map))
      => scalar(value("request")) ... </k>
    [all-path]
endmodule

