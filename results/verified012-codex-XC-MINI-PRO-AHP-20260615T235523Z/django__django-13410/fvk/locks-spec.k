requires "mini-python-locks.k"

module LOCKS-SPEC
  imports MINI-PYTHON-LOCKS
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: "fcntl module returns None if successful, and raises an
  //   OSError to indicate failure" => success and OSError are the two modeled
  //   POSIX fcntl outcomes.
  // - from_prompt: "requires a valid return value to know if they have
  //   successfully acquired the lock" => lock success must return true.
  // - from_code: _fd(f) extracts a file descriptor; this claim models the path
  //   after descriptor extraction succeeds for a non-negative descriptor.
  claim <k> lock(fd(FD), ok) => return(true) ... </k>
    requires FD >=Int 0
    [all-path, label(lock-success)]

  // SPEC-PROVENANCE:
  // - from_prompt: "raises an OSError to indicate failure" and the proposed
  //   public fix returns False from the except OSError branch.
  // - from_prompt: "non-blocking ... requires a valid return value" => an
  //   unavailable non-blocking lock is represented as false, not an exception.
  claim <k> lock(fd(FD), osError) => return(false) ... </k>
    requires FD >=Int 0
    [all-path, label(lock-oserror)]

  // SPEC-PROVENANCE:
  // - from_prompt: the same fcntl return convention applies to the POSIX
  //   unlock helper in the reported patch.
  // - from_code: unlock always invokes fcntl.flock(..., fcntl.LOCK_UN).
  claim <k> unlock(fd(FD), ok) => return(true) ... </k>
    requires FD >=Int 0
    [all-path, label(unlock-success)]

  // SPEC-PROVENANCE:
  // - from_prompt: the reported patch specifies False on OSError for unlock.
  // - from_code: the V1 code catches OSError around the POSIX unlock flock
  //   call and returns False.
  claim <k> unlock(fd(FD), osError) => return(false) ... </k>
    requires FD >=Int 0
    [all-path, label(unlock-oserror)]
endmodule
