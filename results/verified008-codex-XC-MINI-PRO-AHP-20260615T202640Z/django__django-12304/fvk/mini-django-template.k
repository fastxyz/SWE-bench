// Constructed mini semantics for the django__django-12304 FVK audit.
// Not machine-checked in this session.

module MINI-DJANGO-TEMPLATE-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax Name ::= "YearInSchool" | "FRESHMAN"

  syntax Val ::= "none"
               | "invalid"
               | "enumClass" "(" Bool "," Map ")"
               | "member" "(" Name "," Val ")"

  syntax Step ::= "lookup" "(" Name ")"
                | "attr" "(" Name ")"
                | "callGate"
                | "createChoices" "(" Name "," Map ")"

  syntax KResult ::= Val
endmodule

module MINI-DJANGO-TEMPLATE
  imports MINI-DJANGO-TEMPLATE-SYNTAX
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:K </k>
    <context> .Map </context>
    <classes> .Map </classes>
    <current> none </current>

  // Template dictionary/context lookup.
  rule <k> lookup(X) => .K ... </k>
       <context> ... X |-> V:Val ... </context>
       <current> _ => V </current>

  // The existing Django template resolver behavior:
  // a callable value marked do_not_call_in_templates is preserved.
  rule <k> callGate => .K ... </k>
       <current> enumClass(true, MEMBERS) => enumClass(true, MEMBERS) </current>

  // Diagnostic abstraction of the legacy failure:
  // an unmarked callable enum class is called/invalidated before attr lookup.
  rule <k> callGate => .K ... </k>
       <current> enumClass(false, MEMBERS) => invalid </current>

  // Non-callable enum members pass through the callable gate unchanged.
  rule <k> callGate => .K ... </k>
       <current> member(NAME, VALUE) => member(NAME, VALUE) </current>

  // Dotted attribute/member lookup on the preserved enum class.
  rule <k> attr(A) => .K ... </k>
       <current> enumClass(MARKED, MEMBERS) => MEMBERS[A] </current>

  // ChoicesMeta.__new__ creates choices classes with the template marker.
  rule <k> createChoices(C, MEMBERS) => .K ... </k>
       <classes> CLASSES => CLASSES [ C <- enumClass(true, MEMBERS) ] </classes>
endmodule
