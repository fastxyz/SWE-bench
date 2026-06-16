requires "mini-django-view.k"

module DJANGO-VIEW-SPEC
  imports MINI-DJANGO-VIEW

  // SPEC-PROVENANCE:
  // - E1: issue reports TypeError when async POST-only view receives GET.
  // - E2: public hint requires http_method_not_allowed() to handle async like
  //   options().
  // - E3/E4: async class-based views are detected and run in async context.
  // CLAIM: ASYNC-NOT-ALLOWED-AWAITABLE
  claim
    <k> dispatch(asyncView, GET, missingHandler, Allowed)
     => awaitable(response(methodNotAllowed, Allowed)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1: final observable should be a 405 response, not TypeError/500.
  // - E5: http_method_not_allowed() returns HttpResponseNotAllowed with allowed
  //   methods.
  // CLAIM: ASYNC-NOT-ALLOWED-AWAIT
  claim
    <k> await(awaitable(response(methodNotAllowed, Allowed)))
     => direct(response(methodNotAllowed, Allowed)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: both sync and async cases must be handled.
  // - E5: sync default remains HttpResponseNotAllowed with allowed methods.
  // CLAIM: SYNC-NOT-ALLOWED-DIRECT
  claim
    <k> dispatch(syncView, GET, missingHandler, Allowed)
     => direct(response(methodNotAllowed, Allowed)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/DA2: response status/header semantics come from
  //   HttpResponseNotAllowed(self._allowed_methods()).
  // CLAIM: ALLOW-HEADER-PRESERVED
  claim
    <k> httpMethodNotAllowed(asyncView, Allowed)
     => awaitable(response(methodNotAllowed, Allowed)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E6: http_method_not_allowed() must use the same adaptation shape as
  //   options().
  // CLAIM: OPTIONS-PARITY
  claim
    <k> options(asyncView, Allowed)
     => awaitable(response(ok, Allowed)) </k>
    [all-path]
endmodule
