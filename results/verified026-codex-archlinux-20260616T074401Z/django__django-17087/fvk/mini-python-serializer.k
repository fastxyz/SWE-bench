module MINI-PYTHON-SERIALIZER-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Value ::= classMethod(String, String, String)
                 | functionValue(String, String, String)
                 | lambdaFunction
                 | noModuleFunction(String)

  syntax Outcome ::= serialized(String, String)
                   | valueError(String)

  syntax KItem ::= serialize(Value)

  syntax Bool ::= hasLocalMarker(String) [function]

  syntax String ::= dottedClassMethod(String, String, String) [function]
                  | dottedFunction(String, String) [function]
                  | importStmt(String) [function]
                  | couldNotFind(String, String) [function]
endmodule

module MINI-PYTHON-SERIALIZER
  imports MINI-PYTHON-SERIALIZER-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:K </k>

  rule dottedClassMethod(MODULE:String, CLASSQUAL:String, NAME:String)
    => MODULE +String "." +String CLASSQUAL +String "." +String NAME

  rule dottedFunction(MODULE:String, QUAL:String)
    => MODULE +String "." +String QUAL

  rule importStmt(MODULE:String) => "import " +String MODULE

  rule couldNotFind(NAME:String, MODULE:String)
    => "Could not find function " +String NAME +String " in " +String MODULE +String "\n"

  rule <k> serialize(lambdaFunction)
        => valueError("Cannot serialize function: lambda") ... </k>

  rule <k> serialize(classMethod(MODULE:String, CLASSQUAL:String, NAME:String))
        => serialized(dottedClassMethod(MODULE, CLASSQUAL, NAME), importStmt(MODULE))
        ... </k>
    requires notBool hasLocalMarker(CLASSQUAL)

  rule <k> serialize(classMethod(MODULE:String, CLASSQUAL:String, NAME:String))
        => valueError(couldNotFind(NAME, MODULE)) ... </k>
    requires hasLocalMarker(CLASSQUAL)

  rule <k> serialize(noModuleFunction(NAME:String))
        => valueError("Cannot serialize function: No module") ... </k>

  rule <k> serialize(functionValue(MODULE:String, QUAL:String, NAME:String))
        => serialized(dottedFunction(MODULE, QUAL), importStmt(MODULE)) ... </k>
    requires notBool hasLocalMarker(QUAL)

  rule <k> serialize(functionValue(MODULE:String, QUAL:String, NAME:String))
        => valueError(couldNotFind(NAME, MODULE)) ... </k>
    requires hasLocalMarker(QUAL)
endmodule
