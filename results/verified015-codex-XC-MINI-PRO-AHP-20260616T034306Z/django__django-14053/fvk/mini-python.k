module MINI-PYTHON-STATICFILES-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX

  // Abstract events produced by HashedFilesMixin._post_process().
  // ev(name, adjustable, hashed_name, processed, substitutions)
  syntax Event ::= ev(String, Bool, String, Bool, Bool)
                 | ex(String)

  syntax Out ::= out(String, String, Bool)
               | err(String)

  syntax Pgm ::= emitPostProcess(List, List, Bool)

  syntax KItem ::= scanFirst(List, List, Bool)
                 | scanPasses(List, Bool)
                 | scanPass(List, List, Bool, Bool)
                 | flush(Map)

  syntax List ::= values(Map) [function]
endmodule

module MINI-PYTHON-STATICFILES
  imports MINI-PYTHON-STATICFILES-SYNTAX
  imports BOOL
  imports LIST
  imports MAP

  configuration
    <k> $PGM:Pgm </k>
    <deferred> .Map </deferred>
    <out> .List </out>

  rule <k> emitPostProcess(FIRST, PASSES, MAX) => scanFirst(FIRST, PASSES, MAX) ... </k>

  rule <k> scanFirst(.List, PASSES, MAX) => scanPasses(PASSES, MAX) ... </k>

  rule <k> scanFirst(ListItem(ev(N, true, H, P, S)) REST, PASSES, MAX)
        => scanFirst(REST, PASSES, MAX) ... </k>
       <deferred> D => D [N <- out(N, H, P)] </deferred>

  rule <k> scanFirst(ListItem(ev(N, false, H, P, S)) REST, PASSES, MAX)
        => scanFirst(REST, PASSES, MAX) ... </k>
       <out> O => O ListItem(out(N, H, P)) </out>

  rule <k> scanFirst(ListItem(ex(N)) REST, PASSES, MAX) => .K ... </k>
       <out> O => O ListItem(err(N)) </out>

  rule <k> scanPasses(.List, false) => flush(D) ... </k>
       <deferred> D </deferred>

  rule <k> scanPasses(.List, true) => .K ... </k>
       <out> O => O ListItem(err("All")) </out>

  rule <k> scanPasses(ListItem(PASS) REST, MAX)
        => scanPass(PASS, REST, false, MAX) ... </k>

  rule <k> scanPass(.List, REST, false, MAX) => flush(D) ... </k>
       <deferred> D </deferred>

  rule <k> scanPass(.List, REST, true, MAX) => scanPasses(REST, MAX) ... </k>

  rule <k> scanPass(ListItem(ev(N, true, H, P, S)) PASSREST, REST, SEEN, MAX)
        => scanPass(PASSREST, REST, SEEN orBool S, MAX) ... </k>
       <deferred> D => D [N <- out(N, H, P)] </deferred>

  rule <k> scanPass(ListItem(ex(N)) PASSREST, REST, SEEN, MAX) => .K ... </k>
       <out> O => O ListItem(err(N)) </out>

  rule <k> flush(D) => .K ... </k>
       <out> O => O values(D) </out>
endmodule
