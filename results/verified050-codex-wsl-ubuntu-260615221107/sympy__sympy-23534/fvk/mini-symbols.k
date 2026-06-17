module MINI-SYMBOLS-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Class ::= "SymbolCls" | "FunctionCls" | "OtherCls" "(" String ")"

  syntax NameSpec ::= str(String)
                    | range(String, Int, Int)
                    | tuple(NameSpecs)

  syntax NameSpecs ::= ".NameSpecs"
                     | NameSpec ";" NameSpecs [right, klabel(nameSpecsCons)]

  syntax Obj ::= obj(Class, String)

  syntax Value ::= atom(Obj)
                 | tupleValue(Values)

  syntax Values ::= ".Values"
                  | Value ";" Values [right, klabel(valuesCons)]

  syntax KResult ::= Value
  syntax Exp ::= symbols(NameSpec, Class)
endmodule

module MINI-SYMBOLS
  imports MINI-SYMBOLS-SYNTAX
  imports INT
  imports STRING

  configuration <k> $PGM:Exp </k>

  // String names construct one object with the caller-provided class.
  rule <k> symbols(str(N), C) => atom(obj(C, N)) </k>

  // Range names expand into a tuple of objects with the caller-provided class.
  rule <k> symbols(range(P, A, B), C) => tupleValue(rangeValues(P, A, B, C)) </k>

  // Iterable names recurse over children while preserving the caller class.
  rule <k> symbols(tuple(NS), C) => tupleValue(symbolsEach(NS, C)) </k>

  syntax Values ::= rangeValues(String, Int, Int, Class) [function]
  rule rangeValues(P, A, B, C) => .Values
    requires A >=Int B
  rule rangeValues(P, A, B, C)
    => atom(obj(C, P +String Int2String(A))) ; rangeValues(P, A +Int 1, B, C)
    requires A <Int B

  syntax Values ::= symbolsEach(NameSpecs, Class) [function]
  rule symbolsEach(.NameSpecs, C) => .Values
  rule symbolsEach(N ; NS, C) => symbolsValue(N, C) ; symbolsEach(NS, C)

  syntax Value ::= symbolsValue(NameSpec, Class) [function]
  rule symbolsValue(str(N), C) => atom(obj(C, N))
  rule symbolsValue(range(P, A, B), C) => tupleValue(rangeValues(P, A, B, C))
  rule symbolsValue(tuple(NS), C) => tupleValue(symbolsEach(NS, C))
endmodule
