// Constructed, not machine-checked.
// A tiny state-machine semantics for the ContourSet.set_paths body only.

module MINI-CONTOUR-SET-SYNTAX
  imports BOOL-SYNTAX
  imports MAP-SYNTAX

  syntax PathSeq ::= "#oldPaths" | "#newPaths" | "#otherPaths"
  syntax CacheState ::= "cachePresent" | "cacheAbsent"

  syntax Stmt ::= "set_paths" "(" PathSeq ")"
                | "ifCache" "then" Stmt
                | "invalidateCache"
                | "paths" "=" PathSeq
                | "stale" "=" Bool
                | Stmt ";" Stmt [right]
endmodule

module MINI-CONTOUR-SET
  imports MINI-CONTOUR-SET-SYNTAX
  imports BOOL
  imports MAP

  configuration
    <k> $PGM:Stmt </k>
    <paths> #oldPaths </paths>
    <stale> false </stale>
    <cache> cacheAbsent </cache>
    <other> .Map </other>

  rule <k> set_paths(P:PathSeq)
        => ifCache then invalidateCache ; paths = P ; stale = true
        ... </k>

  rule <k> ifCache then S:Stmt => S ... </k>
       <cache> cachePresent </cache>

  rule <k> ifCache then _:Stmt => .K ... </k>
       <cache> cacheAbsent </cache>

  rule <k> invalidateCache => .K ... </k>
       <cache> _ => cacheAbsent </cache>

  rule <k> paths = P:PathSeq => .K ... </k>
       <paths> _ => P </paths>

  rule <k> stale = B:Bool => .K ... </k>
       <stale> _ => B </stale>

  rule <k> S1:Stmt ; S2:Stmt => S1 ~> S2 ... </k>
  rule <k> .K ~> K => K ... </k>
endmodule

