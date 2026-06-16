// Minimal K-style semantics fragment for the SymPy Morse table audit.
// Constructed, not machine-checked in this task.

module MINI-PYTHON-MORSE-SYNTAX
  imports STRING-SYNTAX
  imports MAP-SYNTAX

  syntax Exp ::= defaultMorseChar()
               | defaultCharMorse()
               | encodeDefault(String)
               | decodeDefault(String)
               | lookup(Map, String)
               | reverse(Map)

  syntax KResult ::= String | Map
endmodule

module MINI-PYTHON-MORSE
  imports MINI-PYTHON-MORSE-SYNTAX
  imports STRING
  imports MAP

  configuration <k> $PGM:Exp </k>

  syntax Map ::= digitMorseChar() [function]
  syntax Map ::= digitCharMorse() [function]

  rule digitMorseChar()
    => "-----" |-> "0"
       ".----" |-> "1"
       "..---" |-> "2"
       "...--" |-> "3"
       "....-" |-> "4"
       "....." |-> "5"
       "-...." |-> "6"
       "--..." |-> "7"
       "---.." |-> "8"
       "----." |-> "9"
       .Map

  rule digitCharMorse()
    => "0" |-> "-----"
       "1" |-> ".----"
       "2" |-> "..---"
       "3" |-> "...--"
       "4" |-> "....-"
       "5" |-> "....."
       "6" |-> "-...."
       "7" |-> "--..."
       "8" |-> "---.."
       "9" |-> "----."
       .Map

  rule <k> defaultMorseChar() => digitMorseChar() ... </k>
  rule <k> defaultCharMorse() => digitCharMorse() ... </k>

  rule <k> encodeDefault(C:String) => lookup(digitCharMorse(), C) ... </k>
  rule <k> decodeDefault(M:String) => lookup(digitMorseChar(), M) ... </k>

  rule <k> lookup(M:Map, K:String) => M [ K ] ... </k>
endmodule

