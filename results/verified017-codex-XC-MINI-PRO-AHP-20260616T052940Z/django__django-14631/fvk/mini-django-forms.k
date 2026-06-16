module MINI-DJANGO-FORMS-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX

  syntax Name ::= String
  syntax Form ::= "form" "(" List ")"
  syntax Audit ::= "auditForm" "(" Form ")"
  syntax AuditResult ::= "audited" "(" Map "," List ")"

  syntax KResult ::= AuditResult
endmodule

module MINI-DJANGO-FORMS
  imports MINI-DJANGO-FORMS-SYNTAX
  imports BOOL
  imports LIST
  imports MAP
  imports K-EQUAL

  configuration
    <k> $PGM:K </k>
    <fields> .List </fields>
    <boundFields> .Map </boundFields>

  syntax Map ::= boundFieldsFor(Form, List) [function]
  syntax Map ::= cleanViaBoundFields(Form, List, Map) [function]
  syntax List ::= changedViaBoundFields(Form, List, Map) [function]

  rule
    <k> auditForm(F:Form) => audited(cleanViaBoundFields(F, NAMES, BFMAP), changedViaBoundFields(F, NAMES, BFMAP)) ... </k>
    <fields> NAMES </fields>
    <boundFields> BFMAP </boundFields>
    requires BFMAP ==K boundFieldsFor(F, NAMES)
endmodule
