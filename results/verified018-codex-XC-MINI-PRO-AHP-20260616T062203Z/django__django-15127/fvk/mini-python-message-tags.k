// Mini semantics for the django message tag refresh property.
// Status: constructed, not machine-checked.

module MINI-PYTHON-MESSAGE-TAGS-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX

  syntax Action ::= "updateLevelTags" "(" String ")"
                  | "messageLevelTag" "(" Int ")"
  syntax KResult ::= String | Map
endmodule

module MINI-PYTHON-MESSAGE-TAGS
  imports MINI-PYTHON-MESSAGE-TAGS-SYNTAX
  imports INT
  imports STRING
  imports MAP

  configuration
    <k> $PGM:Action </k>
    <settingsTags> .Map </settingsTags>
    <defaultTags> .Map </defaultTags>
    <levelTags> .Map </levelTags>
    <levelTagsObject> 0 </levelTagsObject>
    <result> "" </result>

  // Spec vocabulary for Python's {**DEFAULT_TAGS, **MESSAGE_TAGS}.
  syntax Map ::= mergeTags(Map, Map) [function]

  // Spec vocabulary for dict.get(level, '').
  syntax String ::= tagOf(Map, Int) [function]

  rule
    <k> updateLevelTags("MESSAGE_TAGS") => .K </k>
    <settingsTags> S:Map </settingsTags>
    <defaultTags> D:Map </defaultTags>
    <levelTags> _ => mergeTags(D, S) </levelTags>

  rule
    <k> updateLevelTags(SETTING:String) => .K </k>
    <levelTags> T:Map => T </levelTags>
    requires SETTING =/=String "MESSAGE_TAGS"

  rule
    <k> messageLevelTag(L:Int) => .K </k>
    <levelTags> T:Map </levelTags>
    <result> _ => tagOf(T, L) </result>
endmodule
