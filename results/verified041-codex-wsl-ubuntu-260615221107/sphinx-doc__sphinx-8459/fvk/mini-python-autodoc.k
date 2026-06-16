module MINI-PYTHON-AUTODOC-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX
  imports BOOL-SYNTAX

  syntax Stmt ::= "recordTypehints" "(" String "," Map "," Map ")"
                | "recordTypehintsPreFix" "(" String "," Map ")"
                | "mergeTypehints" "(" String "," Map "," Map ")"

  syntax KResult ::= Map | String | Bool
endmodule

module MINI-PYTHON-AUTODOC
  imports MINI-PYTHON-AUTODOC-SYNTAX
  imports MAP
  imports BOOL
  imports STRING

  configuration
    <k> $PGM:Stmt </k>
    <annotations> .Map </annotations>
    <fields> .Map </fields>

  syntax Map ::= resolveMap(Map, Map) [function]
  syntax String ::= resolveAnn(String, Map) [function]
  syntax String ::= expandAnn(String) [function]
  syntax Map ::= mergeRecorded(Map, Map) [function]

  // SPEC-PROVENANCE:
  // - from_docs: autodoc_type_aliases keeps aliases not evaluated in the document.
  // - from_code: V1 uses inspect.signature(..., type_aliases=aliases) before stringify.
  rule <k> recordTypehints(NAME:String, RAW:Map, ALIASES:Map) => .K </k>
       <annotations> STORE => STORE [ NAME <- resolveMap(RAW, ALIASES) ] </annotations>

  // SPEC-PROVENANCE:
  // - from_issue: this models the old behavior that produced expanded Dict[str, Any].
  rule <k> recordTypehintsPreFix(NAME:String, RAW:Map) => .K </k>
       <annotations> STORE => STORE [ NAME <- resolveMap(RAW, .Map) ] </annotations>

  // SPEC-PROVENANCE:
  // - from_code: modify_field_list copies recorded annotation strings into fields.
  rule <k> mergeTypehints(NAME:String, RECORDED:Map, EXISTING:Map) => .K </k>
       <fields> FIELDS:Map => FIELDS [ NAME <- mergeRecorded(RECORDED, EXISTING) ] </fields>

  // Concrete reductions for the public issue shape.  The abstraction is
  // property-complete for the disputed observable: alias target vs expanded type.
  rule resolveMap("data" |-> "JSONObject" "return" |-> "JSONObject",
                  "JSONObject" |-> "types.JSONObject")
    => "data" |-> "types.JSONObject" "return" |-> "types.JSONObject"

  rule resolveMap("data" |-> "JSONObject" "return" |-> "JSONObject", .Map)
    => "data" |-> "Dict[str, Any]" "return" |-> "Dict[str, Any]"

  rule mergeRecorded("data" |-> "types.JSONObject" "return" |-> "types.JSONObject",
                     .Map)
    => "type data" |-> "types.JSONObject" "rtype" |-> "types.JSONObject"

  rule mergeRecorded("data" |-> "types.JSONObject" "return" |-> "types.JSONObject",
                     "type data" |-> "UserType" "rtype" |-> "UserReturn")
    => "type data" |-> "UserType" "rtype" |-> "UserReturn"
endmodule
