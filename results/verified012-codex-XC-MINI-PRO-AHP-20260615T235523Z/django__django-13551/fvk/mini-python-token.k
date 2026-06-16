module MINI-PYTHON-TOKEN-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax Login ::= noLogin()
                 | someLogin(String)

  syntax Email ::= noEmail()
                 | nullEmail()
                 | email(String)

  syntax Fields ::= missingFields()
                  | field(String, Email)

  syntax User ::= user(Int, String, Login, String, Fields)

  syntax HashInput ::= hashInput(Int, String, Login, Int, String)
  syntax Digest ::= digest(HashInput) [function]
  syntax Token ::= token(Int, Digest)

  syntax KItem ::= makeHashValue(User, Int)
                 | makeToken(User, Int)
                 | checkToken(User, Token, Int, Int)

  syntax KResult ::= Bool | String | HashInput | Digest | Token
endmodule

module MINI-PYTHON-TOKEN
  imports MINI-PYTHON-TOKEN-SYNTAX
  imports INT
  imports BOOL
  imports STRING
  imports K-EQUAL

  configuration <k> $PGM:K </k>

  syntax String ::= emailComponent(User) [function]

  rule emailComponent(user(PK, PASSWORD, LOGIN, FIELD, field(FIELD, email(EMAIL)))) => EMAIL
  rule emailComponent(user(PK, PASSWORD, LOGIN, FIELD, field(FIELD, nullEmail()))) => ""
  rule emailComponent(user(PK, PASSWORD, LOGIN, FIELD, missingFields())) => ""

  syntax HashInput ::= hashValue(User, Int) [function]

  rule hashValue(user(PK, PASSWORD, LOGIN, FIELD, FIELDS), T)
    => hashInput(PK, PASSWORD, LOGIN, T, emailComponent(user(PK, PASSWORD, LOGIN, FIELD, FIELDS)))

  rule <k> makeHashValue(USER, T) => hashValue(USER, T) ... </k>

  rule <k> makeToken(USER, T) => token(T, digest(hashValue(USER, T))) ... </k>

  rule <k> checkToken(USER, token(T, DIGEST), NOW, TIMEOUT)
        => ((DIGEST ==K digest(hashValue(USER, T))) andBool ((NOW -Int T) <=Int TIMEOUT))
        ... </k>
endmodule
