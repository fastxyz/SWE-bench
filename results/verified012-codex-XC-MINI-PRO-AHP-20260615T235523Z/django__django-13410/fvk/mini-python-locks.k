requires "domains.md"

module MINI-PYTHON-LOCKS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Fd ::= fd(Int)
  syntax FlockOutcome ::= "ok" | "osError"
  syntax KItem ::= lock(Fd, FlockOutcome)
                 | unlock(Fd, FlockOutcome)
                 | return(Bool)
endmodule

module MINI-PYTHON-LOCKS
  imports MINI-PYTHON-LOCKS-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:K </k>

  // Abstract POSIX fcntl.flock() as the two public outcomes named by the
  // issue: normal completion, or OSError.
  rule <k> lock(FD, ok) => return(true) ... </k>
  rule <k> lock(FD, osError) => return(false) ... </k>
  rule <k> unlock(FD, ok) => return(true) ... </k>
  rule <k> unlock(FD, osError) => return(false) ... </k>
endmodule
