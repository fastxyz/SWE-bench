module MINI-PANDAS-OUTPUT-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Index ::= idx(Id, Int)
  syntax Columns ::= cols(Id, Int) | "noColumns"
  syntax Payload ::= payload(Id, Int, Int)

  syntax Obj ::= df(Payload, Columns, Index)
               | array(Payload)
               | sparse(Payload)
               | "sparseError"

  syntax ColArg ::= "noColArg"
                  | colValue(Columns)
                  | colCallableOk(Columns)
                  | "colCallableRaises"

  syntax Mode ::= "defaultMode" | "pandasMode"

  syntax KItem ::= wrapInPandas(Obj, ColArg, Index)
                 | wrapData(Mode, Bool, Obj, Index, ColArg)
endmodule

module MINI-PANDAS-OUTPUT
  imports MINI-PANDAS-OUTPUT-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  // Sparse output is rejected before pandas wrapping.
  rule <k> wrapInPandas(sparse(P), COLS, IDX) => sparseError ... </k>

  // Existing DataFrame output keeps its own index. Column names are updated only
  // when the resolved column argument is defined.
  rule <k> wrapInPandas(df(P, OLD, DFIDX), colValue(NEW), IDX)
        => df(P, NEW, DFIDX) ... </k>
  rule <k> wrapInPandas(df(P, OLD, DFIDX), colCallableOk(NEW), IDX)
        => df(P, NEW, DFIDX) ... </k>
  rule <k> wrapInPandas(df(P, OLD, DFIDX), noColArg, IDX)
        => df(P, OLD, DFIDX) ... </k>
  rule <k> wrapInPandas(df(P, OLD, DFIDX), colCallableRaises, IDX)
        => df(P, OLD, DFIDX) ... </k>

  // Non-DataFrame output is converted to a new DataFrame with the supplied
  // index, matching the pandas-constructor path in _wrap_in_pandas_container.
  rule <k> wrapInPandas(array(P), colValue(NEW), IDX)
        => df(P, NEW, IDX) ... </k>
  rule <k> wrapInPandas(array(P), colCallableOk(NEW), IDX)
        => df(P, NEW, IDX) ... </k>
  rule <k> wrapInPandas(array(P), noColArg, IDX)
        => df(P, noColumns, IDX) ... </k>
  rule <k> wrapInPandas(array(P), colCallableRaises, IDX)
        => df(P, noColumns, IDX) ... </k>

  // _wrap_data_with_container returns unchanged data unless pandas output and
  // auto-wrapping are both active.
  rule <k> wrapData(defaultMode, AUTO, OBJ, ORIGINALIDX, COLS)
        => OBJ ... </k>
  rule <k> wrapData(pandasMode, false, OBJ, ORIGINALIDX, COLS)
        => OBJ ... </k>
  rule <k> wrapData(pandasMode, true, OBJ, ORIGINALIDX, COLS)
        => wrapInPandas(OBJ, COLS, ORIGINALIDX) ... </k>
endmodule
