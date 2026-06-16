// Constructed FVK artifact, not machine-checked.
// Minimal K-style semantics for the keyboard tokenizer fragment. This models
// the observable property under audit: key/separator token order and text.

module MINI-KEYBOARD-SYNTAX
  imports STRING-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX

  syntax Token ::= key(String) | sep(String)

  syntax KItem ::= splitKeys(String)
                 | splitFrom(String, Int, List)
                 | afterKey(String, Int, List)
                 | finish(List)
endmodule

module MINI-KEYBOARD
  imports MINI-KEYBOARD-SYNTAX
  imports STRING
  imports INT
  imports BOOL
  imports LIST

  configuration
    <k> $PGM:KItem </k>
    <out> .List </out>

  syntax Bool ::= isKeySep(String) [function]
  rule isKeySep("-") => true
  rule isKeySep("+") => true
  rule isKeySep("^") => true
  rule isKeySep(_) => false [owise]

  syntax Bool ::= isSeparatorAt(String, Int) [function]
  rule isSeparatorAt(T:String, I:Int)
    => isSpace(substrString(T, I, I +Int 1))
       orBool isKeySep(substrString(T, I, I +Int 1))
    requires 0 <=Int I andBool I <Int lengthString(T)

  syntax Int ::= keyEnd(String, Int) [function]
  rule keyEnd(T:String, I:Int) => I
    requires I >=Int lengthString(T)
  rule keyEnd(T:String, I:Int) => I
    requires I <Int lengthString(T)
     andBool isSeparatorAt(T, I)
  rule keyEnd(T:String, I:Int) => keyEnd(T, I +Int 1)
    requires I <Int lengthString(T)
     andBool notBool isSeparatorAt(T, I)

  syntax Int ::= tokenKeyEnd(String, Int) [function]
  rule tokenKeyEnd(T:String, I:Int) => keyEnd(T, I +Int 1)
    requires I <Int lengthString(T)
     andBool isKeySep(substrString(T, I, I +Int 1))
  rule tokenKeyEnd(T:String, I:Int) => keyEnd(T, I)
    requires I <Int lengthString(T)
     andBool notBool isKeySep(substrString(T, I, I +Int 1))

  syntax Int ::= spaceEnd(String, Int) [function]
  rule spaceEnd(T:String, I:Int) => I
    requires I >=Int lengthString(T)
  rule spaceEnd(T:String, I:Int) => spaceEnd(T, I +Int 1)
    requires I <Int lengthString(T)
     andBool isSpace(substrString(T, I, I +Int 1))
  rule spaceEnd(T:String, I:Int) => I
    requires I <Int lengthString(T)
     andBool notBool isSpace(substrString(T, I, I +Int 1))

  rule <k> splitKeys(T:String) => splitFrom(T, 0, .List) ... </k>

  rule <k> splitFrom(T:String, I:Int, TS:List) => finish(TS) ... </k>
    requires I >=Int lengthString(T)

  rule <k> splitFrom(T:String, I:Int, TS:List)
        => afterKey(T, tokenKeyEnd(T, I),
                    TS ListItem(key(substrString(T, I, tokenKeyEnd(T, I))))) ... </k>
    requires I <Int lengthString(T)

  rule <k> afterKey(T:String, I:Int, TS:List) => finish(TS) ... </k>
    requires I >=Int lengthString(T)

  rule <k> afterKey(T:String, I:Int, TS:List)
        => splitFrom(T, spaceEnd(T, I),
                     TS ListItem(sep(substrString(T, I, spaceEnd(T, I))))) ... </k>
    requires I <Int lengthString(T)
     andBool isSpace(substrString(T, I, I +Int 1))

  rule <k> afterKey(T:String, I:Int, TS:List)
        => splitFrom(T, I +Int 1,
                     TS ListItem(sep(substrString(T, I, I +Int 1)))) ... </k>
    requires I +Int 1 <Int lengthString(T)
     andBool notBool isSpace(substrString(T, I, I +Int 1))

  rule <k> afterKey(T:String, I:Int, TS:List)
        => finish(appendTrailingKeyChar(TS, substrString(T, I, I +Int 1))) ... </k>
    requires I +Int 1 ==Int lengthString(T)
     andBool notBool isSpace(substrString(T, I, I +Int 1))

  syntax List ::= appendTrailingKeyChar(List, String) [function]
  rule appendTrailingKeyChar(.List, C:String) => ListItem(key(C))
  rule appendTrailingKeyChar(ListItem(key(K:String)), C:String)
    => ListItem(key(K +String C))
  rule appendTrailingKeyChar(ListItem(T:Token) REST:List, C:String)
    => ListItem(T) appendTrailingKeyChar(REST, C) [owise]

  rule <k> finish(TS:List) => .K ... </k>
       <out> _ => TS </out>
endmodule
