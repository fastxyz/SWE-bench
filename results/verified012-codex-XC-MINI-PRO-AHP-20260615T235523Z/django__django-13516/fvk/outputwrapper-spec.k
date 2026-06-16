requires "mini-management-output.k"

module OUTPUTWRAPPER-SPEC-SYNTAX
  imports MINI-MANAGEMENT-OUTPUT-SYNTAX
  syntax Id ::= "out" [token]
endmodule

module OUTPUTWRAPPER-SPEC
  imports MINI-MANAGEMENT-OUTPUT
  imports OUTPUTWRAPPER-SPEC-SYNTAX
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - from_prompt: "flush() on self.stdout/stderr management commands doesn't work."
  //   => explicit flush on the wrapper must delegate to the underlying stream.
  // - from_code: OutputWrapper wraps command stdout/stderr, and V1 adds
  //   OutputWrapper.flush() delegating to _out.flush() when present.
  claim [FLUSH-DELEGATES]:
    <k> wrapper(out).flush() => R:Ret ... </k>
    <streams>
      out |-> (stream(true, B:Int, V:Int, F:Int, R)
               => stream(true, 0, V +Int B, F +Int 1, R))
    </streams>
    requires B >=Int 0 andBool V >=Int 0 andBool F >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_compatibility: Django commands accept custom stream-like objects.
  //   => a stream without flush is not the positive target and should be left alone.
  // - from_code: V1 uses hasattr(self._out, 'flush') before delegation.
  claim [FLUSH-NO-METHOD-NOOP]:
    <k> wrapper(out).flush() => none ... </k>
    <streams> out |-> stream(false, B:Int, V:Int, F:Int, R:Ret) </streams>
    requires B >=Int 0 andBool V >=Int 0 andBool F >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: expected migrate output shows "Applying ..." before work and
  //   "OK" after work.
  // - from_code: migrate writes with ending="" and immediately calls
  //   self.stdout.flush().
  claim [PARTIAL-WRITE-THEN-FLUSH]:
    <k> wrapper(out).writePartial(N:Int) ~> wrapper(out).flush() => R:Ret ... </k>
    <streams>
      out |-> (stream(true, B:Int, V:Int, F:Int, R)
               => stream(true, 0, V +Int B +Int N, F +Int 1, R))
    </streams>
    requires N >=Int 0 andBool B >=Int 0 andBool V >=Int 0 andBool F >=Int 0
    [all-path]
endmodule
