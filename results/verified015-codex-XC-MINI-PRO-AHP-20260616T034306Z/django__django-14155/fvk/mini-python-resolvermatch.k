module MINI-PYTHON-RESOLVERMATCH-SYNTAX
  imports STRING-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX

  syntax View ::= view(String)
                | objectView(String)
                | partial(View, List, Map)

  syntax UrlName ::= noUrlName() | urlName(String)
  syntax RMState ::= rm(View, List, Map, String, String, List, Map, UrlName, List, List, String)
  syntax KItem ::= build(View, List, Map, UrlName, List, List, String)
  syntax KResult ::= RMState
endmodule

module MINI-PYTHON-RESOLVERMATCH
  imports MINI-PYTHON-RESOLVERMATCH-SYNTAX
  imports STRING
  imports LIST
  imports MAP

  configuration <k> $PGM:K </k>

  syntax String ::= path(View) [function]
  rule path(view(P:String)) => P
  rule path(objectView(P:String)) => P
  rule path(partial(V:View, _:List, _:Map)) => path(V)

  syntax String ::= selectedViewName(UrlName, String) [function]
  rule selectedViewName(urlName(N:String), _:String) => N
  rule selectedViewName(noUrlName(), P:String) => P

  syntax List ::= partialArgs(View) [function]
  rule partialArgs(view(_:String)) => .List
  rule partialArgs(objectView(_:String)) => .List
  rule partialArgs(partial(V:View, PA:List, _:Map)) => concatArgs(partialArgs(V), PA)

  syntax Map ::= partialKwargs(View) [function]
  rule partialKwargs(view(_:String)) => .Map
  rule partialKwargs(objectView(_:String)) => .Map
  rule partialKwargs(partial(V:View, _:List, PK:Map)) => mergeKwargs(partialKwargs(V), PK)

  syntax Map ::= mergeKwargs(Map, Map) [function]
  rule mergeKwargs(.Map, K:Map) => K
  rule mergeKwargs(K:Map, .Map) => K
  // Abstract right-biased keyword merge. In the real Python fragment this is
  // dictionary unpacking: {**left, **right}.

  syntax List ::= concatArgs(List, List) [function]
  rule concatArgs(.List, B:List) => B
  rule concatArgs(A:List, .List) => A
  rule concatArgs(A:List, B:List) => A B [owise]

  rule <k> build(V:View, A:List, K:Map, U:UrlName, Apps:List, Namespaces:List, R:String)
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
endmodule
