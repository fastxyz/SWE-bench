module MINI-URLVALIDATOR-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax Auth ::= noAuth
                | user(String)
                | userPass(String, String)

  syntax UrlInput ::= url(String, Auth, Bool, Bool)
  syntax Result ::= valid | invalid
  syntax Check ::= validate(UrlInput)
  syntax KResult ::= Result
endmodule

module MINI-URLVALIDATOR
  imports MINI-URLVALIDATOR-SYNTAX
  imports STRING
  imports BOOL

  configuration <k> $PGM:Check </k>

  syntax Bool ::= hasAllowedScheme(String) [function]
                | authFieldsClean(Auth) [function]
                | cleanField(String) [function]
                | hostAndTailValid(Bool, Bool) [function]

  rule hasAllowedScheme("http") => true
  rule hasAllowedScheme("https") => true
  rule hasAllowedScheme("ftp") => true
  rule hasAllowedScheme("ftps") => true

  rule authFieldsClean(noAuth) => true
  rule authFieldsClean(user(U)) => cleanField(U)
  rule authFieldsClean(userPass(U, P)) => cleanField(U) andBool cleanField(P)

  rule hostAndTailValid(true, true) => true
  rule hostAndTailValid(false, T) => false
  rule hostAndTailValid(H, false) => false

  // Concrete witnesses used by urlvalidator-spec.k.
  rule cleanField("userid") => true
  rule cleanField("password") => true
  rule cleanField("foo%40") => true
  rule cleanField("bar%2f") => true
  rule cleanField("foo/bar") => false
  rule cleanField("foo@bar") => false
  rule cleanField("pa:ss") => false
  rule cleanField("foo?m=bar") => false
  rule cleanField("foo#bar") => false

  rule <k> validate(url(S, A, H, T)) => invalid </k>
    requires notBool hasAllowedScheme(S)

  rule <k> validate(url(S, A, H, T)) => invalid </k>
    requires hasAllowedScheme(S) andBool notBool authFieldsClean(A)

  rule <k> validate(url(S, A, H, T)) => invalid </k>
    requires hasAllowedScheme(S) andBool authFieldsClean(A)
      andBool notBool hostAndTailValid(H, T)

  rule <k> validate(url(S, A, H, T)) => valid </k>
    requires hasAllowedScheme(S) andBool authFieldsClean(A)
      andBool hostAndTailValid(H, T)
endmodule
