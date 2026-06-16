// Constructed, not machine-checked.
// Minimal abstract semantics for the AutocompleteJsonView result-construction
// fragment. It models only the property under audit: map each object through a
// virtual serializer hook and preserve the pagination flag.

module MINI-PYTHON-AUTOCOMPLETE-SYNTAX
  imports BOOL
  imports STRING
  imports LIST

  syntax FieldName ::= field(String)
  syntax Obj       ::= obj(String, String)  // cached id string, cached text string
  syntax Hook      ::= defaultHook | customHook(String)
  syntax Result    ::= result(String, String) | customResult(String, String, String)
  syntax Response  ::= response(List, Bool)

  syntax Result ::= applyHook(Hook, Obj, FieldName) [function]
  syntax List   ::= mapResults(List, FieldName, Hook) [function]
  syntax List   ::= defaultResults(List) [function]
  syntax Response ::= buildResponse(List, FieldName, Bool, Hook) [function]
endmodule

module MINI-PYTHON-AUTOCOMPLETE
  imports MINI-PYTHON-AUTOCOMPLETE-SYNTAX

  rule applyHook(defaultHook, obj(ID, TEXT), FIELD) => result(ID, TEXT)
  rule applyHook(customHook(NAME), obj(ID, TEXT), FIELD) => customResult(NAME, ID, TEXT)

  rule mapResults(.List, FIELD, HOOK) => .List
  rule mapResults(ListItem(OBJ) REST, FIELD, HOOK)
    => ListItem(applyHook(HOOK, OBJ, FIELD)) mapResults(REST, FIELD, HOOK)

  rule defaultResults(.List) => .List
  rule defaultResults(ListItem(obj(ID, TEXT)) REST)
    => ListItem(result(ID, TEXT)) defaultResults(REST)

  rule buildResponse(OBJECTS, FIELD, MORE, HOOK)
    => response(mapResults(OBJECTS, FIELD, HOOK), MORE)
endmodule
