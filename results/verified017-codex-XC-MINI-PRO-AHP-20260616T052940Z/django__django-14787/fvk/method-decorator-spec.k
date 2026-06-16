// Abstract K-style claims for django.utils.decorators.method_decorator().
// Constructed, not machine-checked in this benchmark environment.

requires "mini-method-decorator.k"

module METHOD-DECORATOR-SPEC
  imports MINI-METHOD-DECORATOR

  // SPEC-PROVENANCE:
  // - prompt: "method_decorator() should preserve wrapper assignments"
  // - prompt: "partial object ... does not have ... __name__, __module__ etc"
  claim
    <k> makeBoundCallable(METHOD:Callable, SELF:String)
        => copyAssigned(partial(bound(METHOD, SELF), .Map), METHOD) ... </k>
    requires callableDescriptor(METHOD)
    ensures assignedEqual(copyAssigned(partial(bound(METHOD, SELF), .Map), METHOD), METHOD,
      moduleAttr , nameAttr , qualnameAttr , docAttr , annotationsAttr , .Attrs)
    [all-path]

  // SPEC-PROVENANCE:
  // - prompt example: logger reads func.__name__
  claim
    <k> makeBoundCallable(METHOD:Callable, SELF:String)
        => copyAssigned(partial(bound(METHOD, SELF), .Map), METHOD) ... </k>
    requires callableDescriptor(METHOD) andBool hasAttr(METHOD, nameAttr)
    ensures assignedEqual(copyAssigned(partial(bound(METHOD, SELF), .Map), METHOD), METHOD,
      nameAttr , .Attrs)
    [all-path]
endmodule
