// Constructed mini-K semantics for the paginator iterator fragment.
// This file was not compiled or machine-checked in this environment.

module MINI-PYTHON-PAGINATOR-SYNTAX
  imports INT-SYNTAX
  imports ID-SYNTAX

  syntax Obj ::= "obj" "(" Id ")"
  syntax Page ::= "callPage" "(" Obj "," Int ")"

  syntax IntList ::= ".Ints"
                   | Int ";" IntList [right]

  syntax PageList ::= ".Pages"
                    | Page ";" PageList [right]

  syntax Stmt ::= "iterPages" "(" Obj ")"
                | "yieldPages" "(" Obj "," IntList ")"
                | "emit" "(" Page ")"

  syntax KResult ::= Page | IntList | PageList
endmodule

module MINI-PYTHON-PAGINATOR
  imports MINI-PYTHON-PAGINATOR-SYNTAX
  imports INT
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <pageRange> .Map </pageRange>
    <yielded> .Pages </yielded>

  syntax PageList ::= appendPages(PageList, PageList) [function]
  rule appendPages(.Pages, PS:PageList) => PS
  rule appendPages(P:Page ; PS:PageList, QS:PageList)
    => P ; appendPages(PS, QS)

  syntax PageList ::= pagesFor(Obj, IntList) [function]
  rule pagesFor(P:Obj, .Ints) => .Pages
  rule pagesFor(P:Obj, N:Int ; NS:IntList)
    => callPage(P, N) ; pagesFor(P, NS)

  // Models:
  //   def __iter__(self):
  //       for page_number in self.page_range:
  //           yield self.page(page_number)
  rule
    <k> iterPages(P:Obj) => yieldPages(P, RANGE) ... </k>
    <pageRange> ... P |-> RANGE:IntList ... </pageRange>

  rule <k> yieldPages(P:Obj, .Ints) => .K ... </k>

  rule
    <k> yieldPages(P:Obj, N:Int ; NS:IntList)
      => emit(callPage(P, N)) ~> yieldPages(P, NS) ... </k>

  rule
    <k> emit(PAGE:Page) => .K ... </k>
    <yielded> OUT:PageList => appendPages(OUT, PAGE ; .Pages) </yielded>
endmodule
