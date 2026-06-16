requires "mini-colormap.k"

module COLORMAP-CALL-SPEC
  imports MINI-COLORMAP

  // SPEC-PROVENANCE:
  // - E-004: "xa needs to be big enough to hold self.N + 2" => capacity.
  // - E-005: integer X in [0, N) indexes the colormap => in-range frame.
  // - E-006: bad assignment is last => bad overrides range classification.
  claim
    <k> normalizeIndex(N, V, BAD, CAP) => .K </k>
    <result> 0 => normIndex(N, V, BAD) </result>
    requires N >=Int 0
     andBool ensureCapacity(N +Int 2, CAP) >=Int N +Int 2
    [all-path]

  claim
    <k> normalizeIndex(N, V, false, CAP) => .K </k>
    <result> 0 => V </result>
    requires N >=Int 0
     andBool 0 <=Int V
     andBool V <Int N
     andBool ensureCapacity(N +Int 2, CAP) >=Int N +Int 2
    [all-path]

  claim
    <k> normalizeIndex(N, V, true, CAP) => .K </k>
    <result> 0 => N +Int 2 </result>
    requires N >=Int 0
     andBool ensureCapacity(N +Int 2, CAP) >=Int N +Int 2
    [all-path]
endmodule
