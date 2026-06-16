module MINI-CLI-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX

  syntax Arg ::= longVerbose()
               | shortVerbose()
               | longVerboseValue(String)
               | shortVerboseValue(String)
               | separator()
               | other(String)

  syntax Args ::= ".Args"
                | Arg ";" Args [right]

  syntax Cmd ::= preprocess(Args)
               | done
               | error(String)
               | verboseNargs()

  syntax KResult ::= done | Int | Bool | Args
endmodule

module MINI-CLI
  imports MINI-CLI-SYNTAX
  imports BOOL
  imports INT
  imports STRING

  configuration
    <k> $PGM:Cmd </k>
    <verbose> false </verbose>
    <out> .Args </out>

  syntax Args ::= Args "+Args" Args [function, functional]
  rule .Args +Args REST => REST
  rule (A:Arg ; REST:Args) +Args MORE:Args => A ; (REST +Args MORE)

  rule <k> preprocess(.Args) => done ... </k>

  rule <k> preprocess(separator() ; REST:Args) => done ... </k>
       <out> OUT:Args => OUT +Args (separator() ; REST) </out>

  rule <k> preprocess(longVerbose() ; REST:Args) => preprocess(REST) ... </k>
       <verbose> _ => true </verbose>

  rule <k> preprocess(shortVerbose() ; REST:Args) => preprocess(REST) ... </k>
       <verbose> _ => true </verbose>

  rule <k> preprocess(longVerboseValue(_:String) ; _:Args)
        => error("Option --verbose doesn't expects a value") ... </k>

  rule <k> preprocess(shortVerboseValue(_:String) ; _:Args)
        => error("Option -v doesn't expects a value") ... </k>

  rule <k> preprocess(other(S:String) ; REST:Args) => preprocess(REST) ... </k>
       <out> OUT:Args => OUT +Args (other(S) ; .Args) </out>

  rule <k> verboseNargs() => 0 ... </k>
endmodule
