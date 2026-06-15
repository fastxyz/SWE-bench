requires "domains.k"

module MINI-DJANGO-QUERY-SYNTAX
  imports BOOL-SYNTAX

  syntax State ::= state(
      Bool,  // outer query has filtered relation alias
      Bool,  // inner query has filtered relation alias
      Bool,  // lookup resolution error
      Bool,  // first join has filtered relation
      Bool,  // filtered relation condition is non-empty
      Bool,  // filtered condition uses an alias trim_start would remove
      Bool,  // filtered condition is present in WHERE
      Bool   // first join was trimmed
  )

  syntax Cmd ::= splitExclude | trimStart
endmodule

module MINI-DJANGO-QUERY
  imports MINI-DJANGO-QUERY-SYNTAX
  imports BOOL

  configuration <k> $PGM:Cmd </k>
                <st> state(false, false, false, false, false, false, false, false) </st>

  // V1 split_exclude copies outer filtered relation metadata into the inner query.
  rule <k> splitExclude => .K </k>
       <st> state(true, false, _, FJ, C, UTA, W, T)
         => state(true, true, false, FJ, C, UTA, W, T) </st>

  // No filtered relation alias: frame legacy lookup behavior in this abstraction.
  rule <k> splitExclude => .K </k>
       <st> state(false, IFR, E, FJ, C, UTA, W, T)
         => state(false, IFR, E, FJ, C, UTA, W, T) </st>

  // If trimming a filtered join whose condition survives on remaining aliases,
  // move the condition from ON to WHERE and trim the join.
  rule <k> trimStart => .K </k>
       <st> state(OFR, IFR, E, true, true, false, false, false)
         => state(OFR, IFR, E, true, true, false, true, true) </st>

  // If the condition needs a trimmed alias, keep the join so ON remains valid.
  rule <k> trimStart => .K </k>
       <st> state(OFR, IFR, E, true, true, true, false, false)
         => state(OFR, IFR, E, true, true, true, false, false) </st>

  // Empty filtered condition: old trim behavior is preserved.
  rule <k> trimStart => .K </k>
       <st> state(OFR, IFR, E, FJ, false, UTA, W, false)
         => state(OFR, IFR, E, FJ, false, UTA, W, true) </st>

  // Unfiltered first join: old trim behavior is preserved.
  rule <k> trimStart => .K </k>
       <st> state(OFR, IFR, E, false, C, UTA, W, false)
         => state(OFR, IFR, E, false, C, UTA, W, true) </st>
endmodule

