requires "mini-python-resolvermatch.k"

module RESOLVERMATCH-SPEC
  imports MINI-PYTHON-RESOLVERMATCH
  imports STRING
  imports LIST
  imports MAP

  // SPEC-PROVENANCE:
  // - E1/E2/E3: a partial callback repr must reveal the wrapped callable and bound args.
  // - E4/E5/E8: public func/args/kwargs remain the resolved dispatch triple.
  claim [PARTIAL-REPR]:
    <k> build(partial(view(FPATH:String), PA:List, PK:Map), A:List, K:Map, U:UrlName, Apps:List, Namespaces:List, R:String)
        => rm(
              partial(view(FPATH), PA, PK),
              A,
              K,
              FPATH,
              selectedViewName(U, FPATH),
              concatArgs(PA, A),
              mergeKwargs(PK, K),
              U,
              Apps,
              Namespaces,
              R
           )
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: public source contains nested partial URL patterns.
  // - Default-domain assumption: nested partial args compose inner-to-outer; later keywords override earlier.
  claim [NESTED-PARTIAL-REPR]:
    <k> build(partial(partial(view(FPATH:String), PA1:List, PK1:Map), PA2:List, PK2:Map), A:List, K:Map, U:UrlName, Apps:List, Namespaces:List, R:String)
        => rm(
              partial(partial(view(FPATH), PA1, PK1), PA2, PK2),
              A,
              K,
              FPATH,
              selectedViewName(U, FPATH),
              concatArgs(concatArgs(PA1, PA2), A),
              mergeKwargs(mergeKwargs(PK1, PK2), K),
              U,
              Apps,
              Namespaces,
              R
           )
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - Non-partial behavior is a frame condition; the public issue only names partial callbacks.
  claim [NONPARTIAL-REPR]:
    <k> build(view(FPATH:String), A:List, K:Map, U:UrlName, Apps:List, Namespaces:List, R:String)
        => rm(view(FPATH), A, K, FPATH, selectedViewName(U, FPATH), A, K, U, Apps, Namespaces, R)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E5/E8: public runtime triple and tuple-unpacking compatibility.
  claim [FRAME-PUBLIC-TRIPLE]:
    <k> build(V:View, A:List, K:Map, U:UrlName, Apps:List, Namespaces:List, R:String)
        => rm(
              V,
              A,
              K,
              path(V),
              selectedViewName(U, path(V)),
              concatArgs(partialArgs(V), A),
              mergeKwargs(partialKwargs(V), K),
              U,
              Apps,
              Namespaces,
              R
           )
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - Existing source defines view_path = url_name or _func_path.
  // - E1/E3 require _func_path to be the unwrapped callable path for partials.
  claim [VIEW-NAME-FRAME]:
    <k> build(V:View, A:List, K:Map, U:UrlName, Apps:List, Namespaces:List, R:String)
        => rm(
              V,
              A,
              K,
              path(V),
              selectedViewName(U, path(V)),
              concatArgs(partialArgs(V), A),
              mergeKwargs(partialKwargs(V), K),
              U,
              Apps,
              Namespaces,
              R
           )
    </k>
    [all-path]
endmodule
