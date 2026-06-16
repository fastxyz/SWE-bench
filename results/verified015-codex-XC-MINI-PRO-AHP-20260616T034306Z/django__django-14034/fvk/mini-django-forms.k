// Constructed mini-semantics for the django__django-14034 FVK audit.
// This file was not run. It abstracts the relevant render-time state:
// parent required, require_all_fields, subfield required flags, child widget
// use_required_attribute results, and rendered child required attributes.

module MINI-DJANGO-FORMS-SYNTAX
  imports BOOL-SYNTAX

  syntax Bools ::= ".Bools"
                 | Bool ";" Bools [right]

  syntax KResult ::= Bools

  syntax Bools ::= setWidgetRequired(Bool, Bool, Bools) [function]
                 | renderRequired(Bool, Bool, Bools, Bools) [function]
                 | zipAnd(Bools, Bools) [function]
                 | repeatLike(Bool, Bools) [function]
endmodule

module MINI-DJANGO-FORMS
  imports MINI-DJANGO-FORMS-SYNTAX
  imports BOOL

  configuration <k> $PGM:Bools </k>

  rule setWidgetRequired(PARENT:Bool, true, .Bools) => .Bools
  rule setWidgetRequired(PARENT:Bool, true, FIELD:Bool ; REST:Bools)
    => PARENT ; setWidgetRequired(PARENT, true, REST)

  rule setWidgetRequired(PARENT:Bool, false, .Bools) => .Bools
  rule setWidgetRequired(PARENT:Bool, false, FIELD:Bool ; REST:Bools)
    => (PARENT andBool FIELD) ; setWidgetRequired(PARENT, false, REST)

  rule zipAnd(.Bools, .Bools) => .Bools
  rule zipAnd(USE:Bool ; USES:Bools, REQ:Bool ; REQS:Bools)
    => (USE andBool REQ) ; zipAnd(USES, REQS)

  rule repeatLike(VALUE:Bool, .Bools) => .Bools
  rule repeatLike(VALUE:Bool, _HEAD:Bool ; REST:Bools)
    => VALUE ; repeatLike(VALUE, REST)

  // require_all_fields=True: existing parent attr copying remains in force.
  rule renderRequired(true, PARENT_ATTR:Bool, USES:Bools, REQS:Bools)
    => repeatLike(PARENT_ATTR, REQS)

  // require_all_fields=False: no parent required attr means no child required attr.
  rule renderRequired(false, false, USES:Bools, REQS:Bools)
    => repeatLike(false, REQS)

  // require_all_fields=False: parent required attr is split per child.
  rule renderRequired(false, true, USES:Bools, REQS:Bools)
    => zipAnd(USES, REQS)
endmodule
