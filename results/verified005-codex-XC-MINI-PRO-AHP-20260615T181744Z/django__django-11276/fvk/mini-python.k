// Minimal K-style semantics fragment for the django.utils.html.escape audit.
// Constructed, not machine-checked.
//
// This is intentionally not full Python. It models only the observable pieces
// used by the audited wrapper:
// - str() coercion for eager values represented as Obj(S) or SafeString(S)
// - stdlib html.escape(S, quote=True), abstracted as HtmlEscape(S)
// - mark_safe(S), represented as SafeString(S)
// - the local urlize entity helper, abstracted as UrlEntityUnescape(S)

module MINI-DJANGO-HTML-SYNTAX
  imports STRING

  syntax Obj ::= Obj(String)
               | SafeString(String)

  syntax Exp ::= String
               | Obj
               | "str" "(" Obj ")"
               | "_html_escape" "(" String ")"
               | "mark_safe" "(" String ")"
               | "escape" "(" Obj ")"
               | "url_unescape" "(" String ")"

  syntax String ::= HtmlEscape(String) [function, total]
                  | UrlEntityUnescape(String) [function, total]
endmodule

module MINI-DJANGO-HTML
  imports MINI-DJANGO-HTML-SYNTAX

  configuration <k> $PGM:Exp </k>

  rule <k> str(Obj(S)) => S ... </k>
  rule <k> str(SafeString(S)) => S ... </k>

  // Public issue obligation: the wrapper delegates to stdlib html.escape().
  rule <k> _html_escape(S) => HtmlEscape(S) ... </k>

  // Django wrapper obligation: escaped output remains marked safe.
  rule <k> mark_safe(S) => SafeString(S) ... </k>

  // The audited implementation body.
  rule <k> escape(O) => mark_safe(_html_escape(str(O))) ... </k>

  // The local urlize helper is modeled separately from the full urlize parser.
  rule <k> url_unescape(S) => UrlEntityUnescape(S) ... </k>
endmodule
