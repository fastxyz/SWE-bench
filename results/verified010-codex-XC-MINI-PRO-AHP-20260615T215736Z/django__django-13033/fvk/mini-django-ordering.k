requires "domains.md"

module MINI-DJANGO-ORDERING-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Mode ::= "direct" | "expand"
  syntax Field ::= field(Bool, String, Bool)
  syntax Lookup ::= lookup(String, String, Bool)
  syntax Mode ::= classify(Field, Lookup) [function]
endmodule

module MINI-DJANGO-ORDERING
  imports MINI-DJANGO-ORDERING-SYNTAX
  imports BOOL
  imports STRING

  // Abstract model of SQLCompiler.find_ordering_name()'s default-ordering
  // decision. Field is field(is_relation, attname, related_opts_has_ordering).
  // Lookup is lookup(full_name, final_piece, is_pk_shortcut).
  rule classify(field(false, _A, _O), lookup(_N, _P, _PK)) => direct
  rule classify(field(true, _A, false), lookup(_N, _P, _PK)) => direct
  rule classify(field(true, _A, true), lookup(_N, _P, true)) => direct
  rule classify(field(true, A, true), lookup(_N, P, false)) => direct
    requires A ==String P
  rule classify(field(true, A, true), lookup(_N, P, false)) => expand
    requires A =/=String P
endmodule
