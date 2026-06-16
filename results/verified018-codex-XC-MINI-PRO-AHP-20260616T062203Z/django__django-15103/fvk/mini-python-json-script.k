module MINI-PYTHON-JSON-SCRIPT-SYNTAX
  imports STRING-SYNTAX

  syntax Value ::= value(String)
  syntax IdArg ::= omitted | noneId | id(String)
  syntax Exp ::= jsonScript(Value, IdArg)
               | filterJsonScript(Value, IdArg)

  syntax KResult ::= String
endmodule

module MINI-PYTHON-JSON-SCRIPT
  imports MINI-PYTHON-JSON-SCRIPT-SYNTAX
  imports STRING

  configuration <k> $PGM:Exp </k>

  // Abstract specification functions for Django's existing helpers.
  // JSONESC(V) means json.dumps(V, cls=DjangoJSONEncoder) followed by the
  // _json_script_escapes translation for '<', '>', and '&'.
  syntax String ::= JSONESC(Value) [function]

  // HTMLESC(E) means conditional_escape(E), as applied by format_html().
  syntax String ::= HTMLESC(String) [function]

  rule <k> jsonScript(V:Value, omitted) => "<script type=\"application/json\">" +String JSONESC(V) +String "</script>" </k>
  rule <k> jsonScript(V:Value, noneId) => "<script type=\"application/json\">" +String JSONESC(V) +String "</script>" </k>
  rule <k> jsonScript(V:Value, id(E:String)) => "<script id=\"" +String HTMLESC(E) +String "\" type=\"application/json\">" +String JSONESC(V) +String "</script>" </k>

  rule <k> filterJsonScript(V:Value, I:IdArg) => jsonScript(V, I) </k>
endmodule
