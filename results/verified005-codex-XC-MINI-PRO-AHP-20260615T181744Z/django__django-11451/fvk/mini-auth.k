module MINI-AUTH-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports LIST

  syntax MaybeCred ::= noneCred | cred(Id)
  syntax MaybePass ::= nonePass | pass(Id)
  syntax LookupResult ::= missing | found(Id, Bool, Bool)
  syntax DB ::= result(LookupResult)

  syntax Event ::= lookup(Id) | dummyHash(Id) | checkPassword(Id, Id) | canAuth(Id)
  syntax Value ::= retNone | retUser(Id)

  syntax Stmt ::= authenticate(MaybeCred, MaybeCred, MaybePass, DB)
                | doAuthenticate(MaybeCred, MaybePass, DB)

  syntax KResult ::= Value
endmodule

module MINI-AUTH
  imports MINI-AUTH-SYNTAX

  configuration
    <k> $PGM:Stmt </k>
    <events> .List </events>

  // Normalize the username: explicit username wins; otherwise use the
  // USERNAME_FIELD keyword value.
  rule <k> authenticate(noneCred, KW:MaybeCred, P:MaybePass, DB:DB)
        => doAuthenticate(KW, P, DB) ... </k>

  rule <k> authenticate(cred(U), KW:MaybeCred, P:MaybePass, DB:DB)
        => doAuthenticate(cred(U), P, DB) ... </k>

  // Incomplete credentials decline without emitting side-effect events.
  rule <k> doAuthenticate(noneCred, P:MaybePass, DB:DB) => retNone ... </k>

  rule <k> doAuthenticate(cred(U), nonePass, DB:DB) => retNone ... </k>

  // Complete credentials, no matching user: preserve lookup plus dummy hash.
  rule <k> doAuthenticate(cred(U), pass(P), result(missing)) => retNone ... </k>
       <events> ES => ES ListItem(lookup(U)) ListItem(dummyHash(P)) </events>

  // Complete credentials, found user but invalid password.
  rule <k> doAuthenticate(cred(U), pass(P), result(found(User, false, Can)))
        => retNone ... </k>
       <events> ES => ES ListItem(lookup(U)) ListItem(checkPassword(User, P)) </events>

  // Complete credentials, valid password but user cannot authenticate.
  rule <k> doAuthenticate(cred(U), pass(P), result(found(User, true, false)))
        => retNone ... </k>
       <events> ES => ES ListItem(lookup(U)) ListItem(checkPassword(User, P)) ListItem(canAuth(User)) </events>

  // Complete credentials, valid authenticatable user.
  rule <k> doAuthenticate(cred(U), pass(P), result(found(User, true, true)))
        => retUser(User) ... </k>
       <events> ES => ES ListItem(lookup(U)) ListItem(checkPassword(User, P)) ListItem(canAuth(User)) </events>
endmodule
