module MINI-PYTHON-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax MaybeStr ::= absent() | present(String)
  syntax Format ::= defaultFormat()

  syntax DateResult ::= noneResult()
                      | pseudoDate(String, String, String)
                      | formattedDate(String, String, String, Format)
                      | fallbackResult(String)

  syntax KResult ::= DateResult

  syntax KItem ::= valueFromDatadict(MaybeStr, MaybeStr, MaybeStr, DateResult, Format)

  syntax Bool ::= validComplete(String, String, String) [function]
                | valueErrorComplete(String, String, String) [function]
                | overflowComplete(String, String, String) [function]
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:KItem </k>

  rule <k> valueFromDatadict(present(""), present(""), present(""), LEGACY, FMT)
        => noneResult()
        ... </k>

  rule <k> valueFromDatadict(present(Y), present(M), present(D), LEGACY, FMT)
        => formattedDate(Y, M, D, FMT)
        ... </k>
    requires notBool (Y ==String "" andBool M ==String "" andBool D ==String "")
     andBool validComplete(Y, M, D)

  rule <k> valueFromDatadict(present(Y), present(M), present(D), LEGACY, FMT)
        => pseudoDate(Y, M, D)
        ... </k>
    requires notBool (Y ==String "" andBool M ==String "" andBool D ==String "")
     andBool valueErrorComplete(Y, M, D)

  rule <k> valueFromDatadict(present(Y), present(M), present(D), LEGACY, FMT)
        => pseudoDate(Y, M, D)
        ... </k>
    requires notBool (Y ==String "" andBool M ==String "" andBool D ==String "")
     andBool overflowComplete(Y, M, D)

  rule <k> valueFromDatadict(absent(), M, D, LEGACY, FMT)
        => LEGACY
        ... </k>

  rule <k> valueFromDatadict(Y, absent(), D, LEGACY, FMT)
        => LEGACY
        ... </k>

  rule <k> valueFromDatadict(Y, M, absent(), LEGACY, FMT)
        => LEGACY
        ... </k>
endmodule

