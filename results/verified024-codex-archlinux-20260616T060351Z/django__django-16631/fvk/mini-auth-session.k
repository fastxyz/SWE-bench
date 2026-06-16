module MINI-AUTH-SESSION-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Hash ::= "hmac" "(" Int "," Int ")"
  syntax MaybeHash ::= "noHash" | "some" "(" Hash ")"
  syntax Keys ::= ".Keys" | Int ";" Keys [right]
  syntax Session ::= "session" "(" Int "," Bool "," MaybeHash "," Bool ")"
  syntax User ::= "user" "(" Int "," Int "," Bool "," Keys ")"
  syntax Outcome ::= "authenticated" "(" Session ")"
                   | "anonymous" "(" Session ")"
                   | "reuse" "(" Session ")"
                   | "flushThenLogin" "(" Session ")"
  syntax Action ::= "getUser" "(" Session "," User "," Int ")"
                  | "login" "(" Session "," User "," Int ")"
  syntax KResult ::= Bool | Hash | MaybeHash | Keys | Session | User | Outcome
endmodule

module MINI-AUTH-SESSION
  imports MINI-AUTH-SESSION-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Action </k>

  syntax Bool ::= currentMatches(MaybeHash, Int, Int) [function]
  rule currentMatches(noHash, CUR:Int, PWD:Int) => false
  rule currentMatches(some(hmac(CUR:Int, PWD:Int)), CUR, PWD) => true
  rule currentMatches(some(H:Hash), CUR:Int, PWD:Int) => false
    requires H =/=K hmac(CUR, PWD)

  syntax Bool ::= fallbackMatches(MaybeHash, Int, Keys) [function]
  rule fallbackMatches(noHash, PWD:Int, KS:Keys) => false
  rule fallbackMatches(some(H:Hash), PWD:Int, .Keys) => false
  rule fallbackMatches(some(hmac(K:Int, PWD:Int)), PWD, K ; KS:Keys) => true
  rule fallbackMatches(some(H:Hash), PWD:Int, K:Int ; KS:Keys)
    => fallbackMatches(some(H), PWD, KS)
    requires H =/=K hmac(K, PWD)

  rule <k> getUser(session(UID:Int, true, some(hmac(CUR:Int, PWD:Int)), CYCLED:Bool),
                   user(UID, PWD, SUPPORTS:Bool, FBS:Keys),
                   CUR)
        => authenticated(session(UID, true, some(hmac(CUR, PWD)), CYCLED)) </k>

  rule <k> getUser(session(UID:Int, true, H:MaybeHash, CYCLED:Bool),
                   user(UID, PWD:Int, true, FBS:Keys),
                   CUR:Int)
        => authenticated(session(UID, true, some(hmac(CUR, PWD)), true)) </k>
    requires notBool currentMatches(H, CUR, PWD)
     andBool fallbackMatches(H, PWD, FBS)

  rule <k> getUser(session(UID:Int, true, H:MaybeHash, CYCLED:Bool),
                   user(UID, PWD:Int, SUPPORTS:Bool, FBS:Keys),
                   CUR:Int)
        => anonymous(session(UID, false, noHash, true)) </k>
    requires notBool currentMatches(H, CUR, PWD)
     andBool notBool (SUPPORTS andBool fallbackMatches(H, PWD, FBS))

  rule <k> login(session(UID:Int, true, H:MaybeHash, CYCLED:Bool),
                 user(UID, PWD:Int, SUPPORTS:Bool, FBS:Keys),
                 CUR:Int)
        => reuse(session(UID, true, some(hmac(CUR, PWD)), CYCLED)) </k>
    requires currentMatches(H, CUR, PWD)
      orBool (SUPPORTS andBool fallbackMatches(H, PWD, FBS))

  rule <k> login(session(OLDUID:Int, true, H:MaybeHash, CYCLED:Bool),
                 user(UID:Int, PWD:Int, SUPPORTS:Bool, FBS:Keys),
                 CUR:Int)
        => flushThenLogin(session(UID, true, some(hmac(CUR, PWD)), true)) </k>
    requires OLDUID =/=Int UID
      orBool (notBool currentMatches(H, CUR, PWD)
       andBool notBool (SUPPORTS andBool fallbackMatches(H, PWD, FBS)))
endmodule
