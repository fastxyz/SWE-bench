module MINI-PYTHON-SELECTOR-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Config ::= "default" | "pandas" | "invalid"
  syntax DType ::= "homogeneous" | "float16" | "float64" | "category" | "object"

  syntax Data ::= df(Index, Cols, DTypes, Values)
                | array(Index, Int, DType, Values)
                | sparse(Index, Int, DType, Values)

  syntax Index ::= index(List)
  syntax Cols ::= cols(List)
  syntax DTypes ::= dtypes(List)
  syntax Values ::= values(List)
  syntax Mask ::= mask(List)

  syntax KItem ::= transform(Data, Mask, Config, Bool)
                 | afterValidate(Data, Data, Mask, Config, Bool)
                 | validate(Data)
                 | valid(Data)
                 | wrap(Data, Data, Config, Bool)

  syntax Data ::= selectDataFrame(Data, Mask) [function]
                | selectArray(Data, Mask) [function]
                | emptyDataFrame(Data, Mask) [function]
                | emptyArray(Data) [function]

  syntax Bool ::= isDataFrame(Data) [function]
                | anySelected(Mask) [function]
                | configIsPandas(Config) [function]
                | validForSelector(Data) [function]

  syntax Index ::= indexOf(Data) [function]
  syntax Cols ::= colsOf(Data) [function]
  syntax DTypes ::= dtypesOf(Data) [function]
  syntax Values ::= valuesOf(Data) [function]
endmodule

module MINI-PYTHON-SELECTOR
  imports MINI-PYTHON-SELECTOR-SYNTAX
  imports INT
  imports BOOL
  imports LIST

  configuration <k> $PGM:KItem </k>

  rule isDataFrame(df(I:Index, C:Cols, D:DTypes, V:Values)) => true
  rule isDataFrame(array(I:Index, N:Int, D:DType, V:Values)) => false
  rule isDataFrame(sparse(I:Index, N:Int, D:DType, V:Values)) => false

  rule configIsPandas(pandas) => true
  rule configIsPandas(default) => false
  rule configIsPandas(invalid) => false

  rule indexOf(df(I:Index, C:Cols, D:DTypes, V:Values)) => I
  rule colsOf(df(I:Index, C:Cols, D:DTypes, V:Values)) => C
  rule dtypesOf(df(I:Index, C:Cols, D:DTypes, V:Values)) => D
  rule valuesOf(df(I:Index, C:Cols, D:DTypes, V:Values)) => V

  // Spec-level abstraction: selected DataFrame columns preserve the selected
  // original index, columns, dtypes, and values. The list-selection functions
  // are intentionally abstract but are the property-carrying observable.
  syntax List ::= selectList(List, Mask) [function]
  rule selectDataFrame(df(I, cols(CS), dtypes(DS), values(VS)), M)
    => df(I, cols(selectList(CS, M)), dtypes(selectList(DS, M)), values(selectList(VS, M)))

  // Validating a mixed DataFrame may produce a homogeneous array; this is the
  // legacy source of dtype loss if selection happens after validation.
  rule validate(df(I, C, D, V)) => valid(array(I, 0, homogeneous, V))
    requires validForSelector(df(I, C, D, V))
  rule validate(array(I, N, D, V)) => valid(array(I, N, D, V))
    requires validForSelector(array(I, N, D, V))
  rule validate(sparse(I, N, D, V)) => valid(sparse(I, N, D, V))
    requires validForSelector(sparse(I, N, D, V))

  // Transform always validates first. Only after validation can it choose
  // whether the output should be selected from original DataFrame metadata.
  rule <k> transform(X, M, C, AUTO) => validate(X) ~> afterValidate(X, X, M, C, AUTO) </k>
  rule <k> valid(VX) ~> afterValidate(ORIG, X, M, pandas, true)
        => selectDataFrame(ORIG, M) ... </k>
    requires isDataFrame(ORIG) andBool anySelected(M)
  rule <k> valid(VX) ~> afterValidate(ORIG, X, M, pandas, true)
        => emptyDataFrame(ORIG, M) ... </k>
    requires isDataFrame(ORIG) andBool notBool anySelected(M)
  rule <k> valid(VX) ~> afterValidate(ORIG, X, M, C, AUTO)
        => selectArray(VX, M) ... </k>
    requires notBool (isDataFrame(ORIG) andBool configIsPandas(C) andBool AUTO)
             andBool anySelected(M)
  rule <k> valid(VX) ~> afterValidate(ORIG, X, M, C, AUTO)
        => emptyArray(VX) ... </k>
    requires notBool (isDataFrame(ORIG) andBool configIsPandas(C) andBool AUTO)
             andBool notBool anySelected(M)
endmodule
