module MINI-XARRAY-POLYVAL-SYNTAX
  imports INT-SYNTAX

  syntax DType ::= "datetime64" | "timedelta64" | "numeric"
  syntax Raw   ::= dt(Int) | td(Int) | num(Int) | nat
  syntax Num   ::= n(Int) | nan | Num "+N" Num [left] | Num "*N" Num [left]
  syntax Raws  ::= ".Raws" | Raw "," Raws [right]
  syntax Nums  ::= ".Nums" | Num "," Nums [right]
  syntax Coeffs ::= ".Coeffs" | coeff(Int, Num) ";" Coeffs [right]

  syntax KItem ::= ensureNumeric(DType, Raws)
                 | polyval(DType, Raws, Coeffs, Int)
endmodule

module MINI-XARRAY-POLYVAL
  imports MINI-XARRAY-POLYVAL-SYNTAX
  imports INT

  configuration <k> $PGM:K </k>

  // Raw datetime values are modeled as integer nanoseconds since 1970-01-01.
  // Raw timedelta values are modeled as integer nanoseconds since zero duration.
  syntax Num ::= convert(DType, Raw) [function]
  rule convert(datetime64, dt(T)) => n(T)
  rule convert(timedelta64, td(T)) => n(T)
  rule convert(numeric, num(N)) => n(N)
  rule convert(_, nat) => nan

  syntax Nums ::= mapConvert(DType, Raws) [function]
  rule mapConvert(K, .Raws) => .Nums
  rule mapConvert(K, R , RS) => convert(K, R) , mapConvert(K, RS)

  syntax Num ::= coeffAt(Coeffs, Int) [function]
  rule coeffAt(.Coeffs, D) => n(0)
  rule coeffAt(coeff(D, C) ; CS, D) => C
  rule coeffAt(coeff(D0, C) ; CS, D) => coeffAt(CS, D)
    requires D0 =/=Int D

  syntax Num ::= horner(Coeffs, Num, Int, Int) [function]
  rule horner(CS, X, Max, Max) => coeffAt(CS, Max)
  rule horner(CS, X, Deg, Max) => (horner(CS, X, Deg +Int 1, Max) *N X) +N coeffAt(CS, Deg)
    requires Deg <Int Max

  syntax Nums ::= evalAll(Coeffs, Nums, Int) [function]
  rule evalAll(CS, .Nums, Max) => .Nums
  rule evalAll(CS, X , XS, Max) => horner(CS, X, 0, Max) , evalAll(CS, XS, Max)

  rule <k> ensureNumeric(K, RS) => mapConvert(K, RS) </k>
  rule <k> polyval(K, RS, CS, Max) => evalAll(CS, mapConvert(K, RS), Max) </k>
endmodule
