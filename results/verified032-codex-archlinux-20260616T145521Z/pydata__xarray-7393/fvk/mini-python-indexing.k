module MINI-PYTHON-INDEXING-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX

  syntax DType ::= "int32" | "int64" | "object" | "datetime64ns"
  syntax MaybeDType ::= "noDType" | "someDType" "(" DType ")"
  syntax MaybeLevel ::= "noLevel" | "someLevel" "(" String ")"
  syntax Values ::= "values" "(" String "," DType ")"
                  | "pandasLevelValues" "(" Map "," String ")" [function]
                  | "castValues" "(" Values "," DType ")" [function]
  syntax NdArray ::= "ndarray" "(" Values "," DType ")"
  syntax BaseArray ::= "baseArray" "(" Adapter "," MaybeDType ")"
  syntax Adapter ::= "adapter" "(" Map "," DType "," MaybeLevel ")"
  syntax DType ::= "effectiveDType" "(" DType "," MaybeDType ")" [function]

  syntax Exp ::= "__array__" "(" Adapter "," MaybeDType ")"
               | NdArray
               | BaseArray

  syntax Bool ::= "castable" "(" Values "," DType ")" [function]
  syntax KResult ::= NdArray | BaseArray
endmodule

module MINI-PYTHON-INDEXING
  imports MINI-PYTHON-INDEXING-SYNTAX
  imports BOOL
  imports MAP

  configuration <k> $PGM:Exp </k>

  rule effectiveDType(STORED:DType, noDType) => STORED
  rule effectiveDType(_STORED:DType, someDType(REQUESTED:DType)) => REQUESTED

  // Abstract pandas lookup for a MultiIndex level. The map carries a level name
  // to its materialized pandas values.
  rule pandasLevelValues((LEVEL:String |-> V:Values) _REST:Map, LEVEL) => V

  // Abstract NumPy conversion. The value payload is unchanged except for dtype.
  rule castValues(values(PAYLOAD:String, _PANDAS_DTYPE:DType), DTYPE:DType)
    => values(PAYLOAD, DTYPE)

  // V1 level branch: choose the effective dtype, then cast pandas level values.
  rule <k> __array__(adapter(LEVELS:Map, STORED:DType, someLevel(LEVEL:String)), REQ:MaybeDType)
        => ndarray(
             castValues(
               pandasLevelValues(LEVELS, LEVEL),
               effectiveDType(STORED, REQ)
             ),
             effectiveDType(STORED, REQ)
           )
        ... </k>
    requires castable(pandasLevelValues(LEVELS, LEVEL), effectiveDType(STORED, REQ))

  // Compatibility branch for level is None. The base adapter owns the detailed
  // behavior; the MultiIndex adapter must continue to delegate.
  rule <k> __array__(adapter(LEVELS:Map, STORED:DType, noLevel), REQ:MaybeDType)
        => baseArray(adapter(LEVELS, STORED, noLevel), REQ)
        ... </k>
endmodule
