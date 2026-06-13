// mini_auth.k — a minimal ("mini-X") K semantics of *only* the language
// fragment exercised by the V1 fix for django__django-16631:
//
//   * AbstractBaseUser.get_session_auth_hash / _get_session_auth_hash /
//     get_session_auth_fallback_hash   (django/contrib/auth/base_user.py)
//   * the session-hash verification block inside auth.get_user()
//     (django/contrib/auth/__init__.py)
//
// Per the FVK method this is a deliberate stopgap fragment: it models exactly
// the constructs the changed code uses (assignment, if/else, a single while
// loop, boolean short-circuit `and`/`or`, value equality, an opaque hash
// constructor, a list of fallback hashes) and nothing else.
//
// CONSTRUCTED, NOT MACHINE-CHECKED (no kompile/kprove was run; see PROOF.md).

module MINI-AUTH-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports LIST

  // ---- Values -------------------------------------------------------------
  // Opaque secret tokens (SECRET_KEY, fallback keys) and the salt/password are
  // symbolic Vals.  `eps` models an absent/empty session hash, i.e. Python's
  // `None` or "" — the `if not session_hash:` case.  H3(salt, pwd, secret) is
  // the opaque result of `salted_hmac(salt, pwd, secret=...).hexdigest()`.
  // As a K constructor it is injective, which faithfully models "different
  // secret  =>  different hash".
  syntax Val ::= "eps"
               | "H3" "(" Val "," Val "," Val ")"     // salted_hmac(...).hexdigest()

  // Outcome of the verification fragment (a spec-level observation).
  syntax Outcome ::= "KEEP" | "UPGRADE" | "FLUSH"
  syntax Val ::= Outcome

  // ---- Expressions --------------------------------------------------------
  syntax Exp ::= Id | Val | Bool | List
               | "resolve" "(" Exp ")"            [strict]   // None -> SECRET_KEY
               | "head"    "(" Exp ")"            [strict]
               | "tail"    "(" Exp ")"            [strict]
               | "notEmpty" "(" Exp ")"           [strict]
               | "inList"  "(" Exp "," Exp ")"    [strict]    // spec abstraction
               > Exp "==" Exp                     [seqstrict]
               | Exp "!=" Exp                     [seqstrict]
               > "not" Exp                        [strict]
               > Exp "and" Exp                    [strict(1), left]   // short-circuit
               | Exp "or"  Exp                    [strict(1), left]   // short-circuit

  // ---- Statements ---------------------------------------------------------
  syntax Block ::= "{" Stmt "}" | "{" "}"
  syntax Stmt  ::= Id "=" Exp ";"                  [strict(2)]
                 | "if" "(" Exp ")" Block "else" Block [strict(1)]
                 | "while" "(" Exp ")" Block
                 > Stmt Stmt                        [left]

  syntax KResult ::= Val | Bool | List
endmodule

module MINI-AUTH
  imports MINI-AUTH-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST
  imports K-EQUAL

  configuration
    <k> $PGM:Stmt </k>
    <store>  .Map      </store>     // Id |-> Val | Bool | List
    <secret> $SK:Val   </secret>    // settings.SECRET_KEY (symbolic)

  // ---- variable lookup ----------------------------------------------------
  rule <k> X:Id => V ... </k> <store> ... X |-> V ... </store>

  // ---- resolve(): salted_hmac's `secret=None` defaulting -------------------
  //   In django.utils.crypto.salted_hmac: `if secret is None: secret = SECRET_KEY`.
  //   `eps` in *secret position* models that `None`.
  rule <k> resolve(eps)   => SK ... </k> <secret> SK </secret>
  rule <k> resolve(V:Val) => V  ... </k> requires V =/=K eps

  // ---- value / boolean equality (constant_time_compare on hex strings) -----
  rule <k> V1:Val  == V2:Val  => V1 ==K V2     ... </k>
  rule <k> V1:Val  != V2:Val  => notBool (V1 ==K V2) ... </k>
  rule <k> B1:Bool == B2:Bool => B1 ==Bool B2  ... </k>

  // ---- boolean ops (Python and/or short-circuit) --------------------------
  rule <k> not B:Bool      => notBool B ... </k>
  rule <k> true  and E:Exp => E     ... </k>
  rule <k> false and _:Exp => false ... </k>
  rule <k> true  or  _:Exp => true  ... </k>
  rule <k> false or  E:Exp => E     ... </k>

  // ---- list helpers -------------------------------------------------------
  rule <k> head(ListItem(X:Val) _:List)      => X    ... </k>
  rule <k> tail(ListItem(_:Val) Rest:List)   => Rest ... </k>
  rule <k> notEmpty(L:List) => notBool (L ==K .List) ... </k>

  // ---- inList: the spec-only membership abstraction over the fallback list -
  //   inList(H, FB)  ==  "some fallback-key hash in FB equals H".
  //   Its two defining equations are exactly what one scan iteration produces,
  //   which is why the SCAN-LOOP circularity discharges against it (see PROOF.md).
  rule <k> inList(_:Val, .List) => false ... </k>
  rule <k> inList(H:Val, ListItem(X:Val) Rest:List)
        => (X ==K H) orBool inList(H, Rest) ... </k>

  // ---- assignment ---------------------------------------------------------
  rule <k> X:Id = V:KResult ; => .K ... </k>
       <store> STORE => STORE [ X <- V ] </store>

  // ---- if / blocks --------------------------------------------------------
  rule <k> if (true)  B:Block else _:Block => B ... </k>
  rule <k> if (false) _:Block else B:Block => B ... </k>
  rule <k> { S:Stmt } => S   ... </k>
  rule <k> { }        => .K  ... </k>

  // ---- while (re-evaluate a fresh copy of the guard each iteration) --------
  rule <k> while (B:Exp) Body:Block
        => if (B) { Body while (B) Body } else { } ... </k>

  // ---- sequencing ---------------------------------------------------------
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>
endmodule
