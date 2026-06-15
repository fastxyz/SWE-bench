// Constructed mini-K fragment for django admin inline selection.
// Status: constructed, not machine-checked.
//
// This intentionally models only the values and transitions needed by the
// audited patch: default get_inlines(), get_inline_instances() loop behavior,
// and the to_field_allowed() static-inline frame condition.

requires "domains.md"

module MINI-DJANGO-ADMIN-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX

  syntax Obj ::= obj(String)
  syntax Req ::= req(String) | noRequest
  syntax MaybeObj ::= none | someObj(String)
  syntax Class ::= cls(String)
  syntax Instance ::= inst(Obj, Class)

  syntax Exp ::= getInlines(Obj, Req, MaybeObj)
               | getInlineInstances(Obj, Req, MaybeObj)
               | startInlineLoop(Obj, Req, MaybeObj)
               | inlineLoop(Obj, Req, MaybeObj, List, List)
               | toFieldAllowedRegistry(List)
               | checkInlines(Obj)
               | attr(Obj, String)
               | dispatchGetInlines(Obj, Req, MaybeObj)

  syntax Bool ::= hasAnyPermission(Req, MaybeObj, Instance)
                | hasAddPermission(Req, MaybeObj, Instance)
  syntax Instance ::= setMaxNumZero(Instance)
endmodule

module MINI-DJANGO-ADMIN
  imports MINI-DJANGO-ADMIN-SYNTAX
  imports STRING
  imports BOOL
  imports LIST
  imports MAP

  configuration
    <k> $PGM:Exp </k>
    <attrs> .Map </attrs>
    <hookResults> .Map </hookResults>
    <staticRegistries> .Map </staticRegistries>

  // Attribute lookup for the receiver. The attrs map stores
  // OBJ |-> ("inlines" |-> LIST, "model" |-> MODEL, "admin_site" |-> SITE).
  syntax KItem ::= value(K)
  rule <k> attr(SELF, NAME) => value(V) ...</k>
       <attrs> ... SELF |-> ( ... NAME |-> V ... ) ...</attrs>

  // Default ModelAdmin.get_inlines(): return self.inlines.
  rule <k> getInlines(SELF, REQUEST, OBJ) => attr(SELF, "inlines") ...</k>

  // Virtual dispatch abstraction for subclasses. The spec file constrains
  // hookResults where a subclass override is being modeled.
  rule <k> dispatchGetInlines(SELF, REQUEST, OBJ) => value(INLINES) ...</k>
       <hookResults> ... (SELF, REQUEST, OBJ) |-> INLINES ...</hookResults>

  // get_inline_instances() uses the dispatched hook result as its loop input.
  rule <k> getInlineInstances(SELF, REQUEST, OBJ)
        => dispatchGetInlines(SELF, REQUEST, OBJ)
           ~> startInlineLoop(SELF, REQUEST, OBJ)
       ...</k>

  rule <k> value(HOOK_RESULT) ~> startInlineLoop(SELF, REQUEST, OBJ)
        => inlineLoop(SELF, REQUEST, OBJ, HOOK_RESULT, .List)
       ...</k>

  // Empty inline class list: return accumulated instances.
  rule <k> inlineLoop(SELF, REQUEST, OBJ, .List, ACC)
        => value(ACC)
       ...</k>

  // No request: instantiate and append every selected inline class.
  rule <k> inlineLoop(SELF, noRequest, OBJ, ListItem(CLASS) REST, ACC)
        => inlineLoop(SELF, noRequest, OBJ, REST, ACC ListItem(inst(SELF, CLASS)))
       ...</k>

  // Request present, no relevant permissions: skip.
  rule <k> inlineLoop(SELF, REQUEST, OBJ, ListItem(CLASS) REST, ACC)
        => inlineLoop(SELF, REQUEST, OBJ, REST, ACC)
       ...</k>
       requires REQUEST =/=K noRequest
        andBool notBool hasAnyPermission(REQUEST, OBJ, inst(SELF, CLASS))

  // Request present, view/change/delete exists but add is unavailable:
  // append with max_num forced to zero.
  rule <k> inlineLoop(SELF, REQUEST, OBJ, ListItem(CLASS) REST, ACC)
        => inlineLoop(
             SELF, REQUEST, OBJ, REST,
             ACC ListItem(setMaxNumZero(inst(SELF, CLASS)))
           )
       ...</k>
       requires REQUEST =/=K noRequest
        andBool hasAnyPermission(REQUEST, OBJ, inst(SELF, CLASS))
        andBool notBool hasAddPermission(REQUEST, OBJ, inst(SELF, CLASS))

  // Request present and add is allowed: append unchanged instance.
  rule <k> inlineLoop(SELF, REQUEST, OBJ, ListItem(CLASS) REST, ACC)
        => inlineLoop(SELF, REQUEST, OBJ, REST, ACC ListItem(inst(SELF, CLASS)))
       ...</k>
       requires REQUEST =/=K noRequest
        andBool hasAnyPermission(REQUEST, OBJ, inst(SELF, CLASS))
        andBool hasAddPermission(REQUEST, OBJ, inst(SELF, CLASS))

  // Frame model for to_field_allowed(): its registry is static admin.inlines.
  rule <k> toFieldAllowedRegistry(ADMINS) => value(STATIC) ...</k>
       <staticRegistries> ADMINS |-> STATIC </staticRegistries>

  // Frame model for checks: checks read the static attribute.
  rule <k> checkInlines(ADMIN) => attr(ADMIN, "inlines") ...</k>
endmodule
