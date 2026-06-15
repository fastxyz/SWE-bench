requires "mini-python-middleware.k"

module MIDDLEWARE-ASYNC-SPEC
  imports MINI-PYTHON-MIDDLEWARE

  // SPEC-PROVENANCE:
  // - from_prompt: "Coroutine passed to the first middleware's
  //   process_response() instead of HttpResponse." => affected middleware must
  //   be recognized as async when wrapping an async get_response.
  // - from_hint: "SecurityMiddleware : its __init__ does not call
  //   super().__init__(). This causes MiddlewareMixin._async_check() to not be
  //   called..." => constructor must execute the mixin async check.
  claim
    <k> securityInit(true) => .K </k>
    <obj> obj(false, false, false, false, false)
       => obj(true, true, true, false, false)
    </obj>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt/hint: same SecurityMiddleware async obligation.
  // - frame: synchronous wrapping remains synchronous.
  claim
    <k> securityInit(false) => .K </k>
    <obj> obj(false, false, false, false, false)
       => obj(false, false, true, false, false)
    </obj>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: "cache-related middlewares have the same issue" and "The 3
  //   cache middlewares ... need to be changed together" => split cache update
  //   middleware must execute mixin async check.
  claim
    <k> updateCacheInit(true) => .K </k>
    <obj> obj(false, false, false, false, false)
       => obj(true, true, false, true, false)
    </obj>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: same cache-family obligation for FetchFromCacheMiddleware.
  claim
    <k> fetchCacheInit(true) => .K </k>
    <obj> obj(false, false, false, false, false)
       => obj(true, true, false, true, false)
    </obj>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: same cache-family obligation for CacheMiddleware.
  // - from_code: CacheMiddleware has decorator keyword options; the combined
  //   constructor must preserve its own option handling while still executing
  //   the mixin async check.
  claim
    <k> combinedCacheInit(true) => .K </k>
    <obj> obj(false, false, false, false, false)
       => obj(true, true, false, true, true)
    </obj>
    [all-path]
endmodule
