requires "domains.md"

module MINI-PYTHON-SYNTAX
  imports BOOL-SYNTAX

  syntax Obj ::= "none"
               | "ax"
               | "providedRenderer"
               | "figureRenderer"
               | "bboxResult"

  syntax KItem ::= callLocator(Obj, Obj)
                 | setAxes(Obj)
                 | getWindowExtent(Obj)
                 | getOffset(Obj)
                 | makeBbox
                 | done(Obj)
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL

  configuration
    <k> $PGM:K </k>
    <figureRenderer> none </figureRenderer>
    <locatorAxes> none </locatorAxes>

  rule <k> callLocator(AX, R) => setAxes(AX) ~> getWindowExtent(R) ~> getOffset(R) ~> makeBbox ... </k>
    requires R =/=K none

  rule <k> callLocator(AX, none) => setAxes(AX) ~> getWindowExtent(FR) ~> getOffset(FR) ~> makeBbox ... </k>
       <figureRenderer> FR </figureRenderer>
    requires FR =/=K none

  rule <k> setAxes(AX) => . ... </k>
       <locatorAxes> _ => AX </locatorAxes>

  rule <k> getWindowExtent(R) => . ... </k>
    requires R =/=K none

  rule <k> getOffset(R) => . ... </k>
    requires R =/=K none

  rule <k> makeBbox => done(bboxResult) ... </k>
endmodule
