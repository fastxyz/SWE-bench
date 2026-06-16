requires "mini-nthroot.k"

module NTHROOT-MOD-SPEC
  imports MINI-NTHROOT

  // SPEC-PROVENANCE:
  // - from_prompt: "when a % p == 0. Then x = 0 mod p is also a root"
  //   => zero residue must be returned by the default root query.
  // - from_docstring: "all_roots : if False returns the smallest root"
  //   => all_roots=False returns the single integer root.
  // - from_default_domain: for prime P and N > 0, X^N == 0 (mod P)
  //   implies X == 0 (mod P), so 0 is the unique and smallest root.
  claim
    <k> nthrootMod(A:Int, N:Int, P:Int, false, true, true)
     => Single(0) ... </k>
    requires N >Int 0
     andBool N =/=Int 2
     andBool P >Int 1
     andBool A modInt P ==Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "x = 0 mod p is also a root"
  //   => the all-roots query must include zero.
  // - from_docstring: "all_roots : ... the list of roots"
  //   => for the prime zero-residue case, the complete list is [0],
  //   represented here by ZeroList.
  // - from_default_domain: prime uniqueness lemma above.
  claim
    <k> nthrootMod(A:Int, N:Int, P:Int, true, true, true)
     => ZeroList ... </k>
    requires N >Int 0
     andBool N =/=Int 2
     andBool P >Int 1
     andBool A modInt P ==Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: nthroot_mod(..., p=36) raises NotImplementedError
  //   for n > 2 composite-modulus examples.
  // - from_code: V1 places the zero-residue guard after the composite
  //   rejection to preserve that public compatibility boundary.
  claim
    <k> nthrootMod(A:Int, N:Int, P:Int, AllRoots:Bool, true, false)
     => NotImplemented ... </k>
    requires N >Int 0
     andBool N =/=Int 2
     andBool P >Int 1
    [all-path]
endmodule
