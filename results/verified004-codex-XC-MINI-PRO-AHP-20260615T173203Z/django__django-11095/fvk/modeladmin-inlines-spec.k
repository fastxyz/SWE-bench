// Constructed K claims for django__django-11095.
// Status: constructed, not machine-checked.

requires "mini-django-admin.k"

module MODELADMIN-INLINES-SPEC
  imports MINI-DJANGO-ADMIN

  // SPEC-PROVENANCE:
  // - E-001/E-003/E-004: public intent requires a get_inlines hook for inline
  //   classes; default behavior preserves self.inlines.
  claim <k> getInlines(SELF, REQUEST, OBJ) => value(INLINES) </k>
        <attrs> SELF |-> ( "inlines" |-> INLINES ) </attrs>
        <hookResults> .Map </hookResults>
        <staticRegistries> .Map </staticRegistries>

  // SPEC-PROVENANCE:
  // - E-001/E-002/E-003: get_inline_instances must use get_inlines(request,obj)
  //   as its class source so callers do not copy the construction loop.
  claim <k> getInlineInstances(SELF, REQUEST, OBJ)
          => value(FILTERED)
        </k>
        <attrs> SELF |-> ( "inlines" |-> STATIC ) </attrs>
        <hookResults> (SELF, REQUEST, OBJ) |-> DYNAMIC </hookResults>
        <staticRegistries> .Map </staticRegistries>
    ensures FILTERED ==K PermissionFilter(SELF, REQUEST, OBJ, DYNAMIC)

  // SPEC-PROVENANCE:
  // - E-002: only the class source changes. The existing loop's construction
  //   and permission outcomes remain the same for a selected class list.
  claim <k> value(DYNAMIC)
          ~> inlineLoop(SELF, REQUEST, OBJ, DYNAMIC, .List)
          => value(PermissionFilter(SELF, REQUEST, OBJ, DYNAMIC))
        </k>
        <attrs> .Map </attrs>
        <hookResults> .Map </hookResults>
        <staticRegistries> .Map </staticRegistries>

  // SPEC-PROVENANCE:
  // - E-005/F-001: related-object validation must remain based on static
  //   admin.inlines because this path has no object context.
  claim <k> toFieldAllowedRegistry(ADMINS) => value(STATIC) </k>
        <attrs> .Map </attrs>
        <hookResults> DYNAMIC_HOOKS </hookResults>
        <staticRegistries> ADMINS |-> STATIC </staticRegistries>

  // SPEC-PROVENANCE:
  // - E-006/F-003: admin checks stay static because no request/object exists.
  claim <k> checkInlines(ADMIN) => value(STATIC_INLINES) </k>
        <attrs> ADMIN |-> ( "inlines" |-> STATIC_INLINES ) </attrs>
        <hookResults> DYNAMIC_HOOKS </hookResults>
        <staticRegistries> .Map </staticRegistries>

  // Spec-only abstraction: the closed-form result of the unchanged permission
  // loop. The mini semantics' loop rules implement this function by list
  // induction.
  syntax List ::= PermissionFilter(Obj, Req, MaybeObj, List) [function]
endmodule
