// Constructed, not machine-checked.
// Minimal property-complete model for django__django-14608.

module MINI-DJANGO-ERRORLIST-SYNTAX
  imports BOOL-SYNTAX

  syntax Path ::= "unbound" | "clean" | "management" | "validation"
  syntax Errors ::= "noErrors" | "managementErrors" | "validationErrors"
  syntax ExtraClass ::= "noExtra" | "nonform" | "nonfield"
  syntax CssClass ::= "errorlist" | "errorlistNonform" | "errorlistNonfield"
  syntax ErrorList ::= "errorList" "(" Errors "," ExtraClass ")"

  syntax KItem ::= "nonFormErrors" "(" Path ")"
                 | "fullClean" "(" Path ")"
                 | "getNonFormErrors"

  syntax KResult ::= ErrorList | CssClass
endmodule

module MINI-DJANGO-ERRORLIST
  imports MINI-DJANGO-ERRORLIST-SYNTAX

  configuration
    <k> $PGM:KItem </k>
    <nonFormErrors> errorList(noErrors, noExtra) </nonFormErrors>

  syntax Errors ::= "errorsFor" "(" Path ")" [function]
  rule errorsFor(unbound) => noErrors
  rule errorsFor(clean) => noErrors
  rule errorsFor(management) => managementErrors
  rule errorsFor(validation) => validationErrors

  syntax CssClass ::= "classOf" "(" ErrorList ")" [function]
  rule classOf(errorList(_, noExtra)) => errorlist
  rule classOf(errorList(_, nonform)) => errorlistNonform
  rule classOf(errorList(_, nonfield)) => errorlistNonfield

  // Abstracts BaseFormSet.non_form_errors(): if needed, run full_clean(), then
  // return the stored non-form ErrorList.
  rule <k> nonFormErrors(P:Path) => fullClean(P) ~> getNonFormErrors ... </k>

  // Abstracts the relevant BaseFormSet.full_clean() effect after V1:
  // every path constructs _non_form_errors with extra class nonform.
  rule <k> fullClean(P:Path) => .K ... </k>
       <nonFormErrors> _ => errorList(errorsFor(P), nonform) </nonFormErrors>

  rule <k> getNonFormErrors => L:ErrorList ... </k>
       <nonFormErrors> L </nonFormErrors>
endmodule
