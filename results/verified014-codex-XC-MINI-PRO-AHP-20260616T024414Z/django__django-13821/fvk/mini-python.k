requires "domains.md"

module MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  syntax Version ::= version(Int, Int, Int)
  syntax KItem ::= checkSqliteVersion(Version, String)
                 | ok
                 | raised(String)
  syntax Bool ::= below390(Version) [function]
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL
  imports STRING

  configuration <k> $PGM:K </k>

  rule below390(version(M, N, P))
    => M <Int 3
       orBool (M ==Int 3 andBool N <Int 9)
       orBool (M ==Int 3 andBool N ==Int 9 andBool P <Int 0)
    [function]

  rule <k> checkSqliteVersion(V, S)
        => raised("SQLite 3.9.0 or later is required (found " +String S +String ").")
        ...
       </k>
    requires below390(V)

  rule <k> checkSqliteVersion(V, S) => ok ... </k>
    requires notBool below390(V)
endmodule
