module MINI-PYTHON-RESOLVE-LOOKUP-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  syntax Val ::= atom(Id)
               | expr(Id)
               | fexpr(Id)
               | resolved(Id, Bool, Bool)
               | fresolved(Id, Bool, Bool, Bool)
               | pyList(Vals)
               | pyTuple(Vals)

  syntax Vals ::= ".Vals" [klabel(valsEmpty)]
                | Val "," Vals [right, klabel(valsCons)]

  syntax KResult ::= Val | Vals

  syntax Val ::= resolveLookupValue(Val, Bool, Bool, Bool) [function]
  syntax Vals ::= resolveLookupValues(Vals, Bool, Bool, Bool) [function]
endmodule

module MINI-PYTHON-RESOLVE-LOOKUP
  imports MINI-PYTHON-RESOLVE-LOOKUP-SYNTAX
  imports BOOL

  configuration <k> $PGM:Val </k>

  rule resolveLookupValue(fexpr(X:Id), CR:Bool, AJ:Bool, SC:Bool)
    => fresolved(X, CR, AJ, SC)

  rule resolveLookupValue(expr(X:Id), CR:Bool, AJ:Bool, SC:Bool)
    => resolved(X, CR, AJ)

  rule resolveLookupValue(pyList(VS:Vals), CR:Bool, AJ:Bool, SC:Bool)
    => pyList(resolveLookupValues(VS, CR, AJ, SC))

  rule resolveLookupValue(pyTuple(VS:Vals), CR:Bool, AJ:Bool, SC:Bool)
    => pyTuple(resolveLookupValues(VS, CR, AJ, SC))

  rule resolveLookupValue(atom(X:Id), CR:Bool, AJ:Bool, SC:Bool)
    => atom(X)

  rule resolveLookupValues(.Vals, CR:Bool, AJ:Bool, SC:Bool)
    => .Vals

  rule resolveLookupValues((V:Val , VS:Vals), CR:Bool, AJ:Bool, SC:Bool)
    => resolveLookupValue(V, CR, AJ, SC) , resolveLookupValues(VS, CR, AJ, SC)
endmodule

