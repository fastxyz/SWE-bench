module MINI-ADMIN-CHECK-SYNTAX
  imports BOOL-SYNTAX

  syntax FieldKind ::= "regular" | "m2m" | "noneValue"
  syntax Lookup ::= "missing" | "resolved" "(" FieldKind ")"
  syntax Result ::= "ok" | "e108" | "e109"
  syntax Cmd ::= "check" "(" Bool "," Lookup "," Bool "," Lookup ")"
  syntax KResult ::= Result
endmodule

module MINI-ADMIN-CHECK
  imports MINI-ADMIN-CHECK-SYNTAX
  imports BOOL

  configuration <k> $PGM:Cmd </k>

  // Abstracts _check_list_display_item(callable, get_field, admin_attr, model_attr).
  // The four arguments are:
  // 1. callable(item)
  // 2. obj.model._meta.get_field(item): missing or resolved(field kind)
  // 3. hasattr(obj, item)
  // 4. getattr(obj.model, item): missing or resolved(field kind)
  rule <k> check(true,  GF:Lookup, ADMIN:Bool, MA:Lookup) => ok </k>

  rule <k> check(false, resolved(regular), ADMIN:Bool, MA:Lookup) => ok </k>
  rule <k> check(false, resolved(noneValue), ADMIN:Bool, MA:Lookup) => ok </k>
  rule <k> check(false, resolved(m2m),     ADMIN:Bool, MA:Lookup) => e109 </k>

  rule <k> check(false, missing, true,  MA:Lookup) => ok </k>
  rule <k> check(false, missing, false, resolved(regular)) => ok </k>
  rule <k> check(false, missing, false, resolved(noneValue)) => ok </k>
  rule <k> check(false, missing, false, resolved(m2m)) => e109 </k>
  rule <k> check(false, missing, false, missing) => e108 </k>
endmodule

