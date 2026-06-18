requires "verification.k"

module NTHROOT-MOD-SPEC
  imports VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "when a % p == 0. Then x = 0 mod p is also a root"
  // - from_docs: "a : integer"; "n : positive integer"; "p : positive integer"
  // - from_default_domain: Python integer modulo and prime-field zero-product property
  // - from_code: V2 zero-residue branch is before is_nthpow_residue and after n == 2
  // - conflicts: V1 failed negative multiples because is_nthpow_residue rejects a < 0
  claim
    <k> nthroot_mod(A:Int, N:Int, P:Int, false) => 0 ... </k>
    requires N >Int 0 andBool N =/=Int 2 andBool P >Int 0
     andBool isPrime(P) andBool A modInt P ==Int 0
    ensures isNthRoot(0, A, N, P)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: zero must be included as a root for a % p == 0
  // - from_docs: "all_roots ... returns ... the list of roots"
  // - from_default_domain: for prime p, x**n == 0 mod p has exactly the residue 0
  // - from_code: V2 returns zeroRootResult(true), modeled as ListItem(0)
  claim
    <k> nthroot_mod(A:Int, N:Int, P:Int, true) => ListItem(0) ... </k>
    requires N >Int 0 andBool N =/=Int 2 andBool P >Int 0
     andBool isPrime(P) andBool A modInt P ==Int 0
    ensures exactlyZeroRootList(ListItem(0), A, N, P)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: "if n == 2: return sqrt_mod(a, p, all_roots)"
  // - from_compatibility: V1/V2 must not alter the square-root path
  claim
    <k> nthroot_mod(A:Int, 2, P:Int, AR:Bool) => sqrtResult(A, P, AR) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: "if not is_nthpow_residue(a, n, p): return None"
  // - from_compatibility: nonresidue behavior is not part of the zero-root bug
  claim
    <k> nthroot_mod(A:Int, N:Int, P:Int, AR:Bool) => None ... </k>
    requires N =/=Int 2 andBool notBool nthResidue(A, N, P)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: "raise NotImplementedError(\"Not implemented for composite p\")"
  // - from_public_tests: composite examples are expected to raise
  // - from_compatibility: zero-residue branch keeps composite p unimplemented for n > 2
  claim
    <k> nthroot_mod(A:Int, N:Int, P:Int, AR:Bool) => NotImplemented ... </k>
    requires N >Int 0 andBool N =/=Int 2 andBool P >Int 0
     andBool A modInt P ==Int 0 andBool notBool isPrime(P)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: nonzero prime residues continue into the existing nth-root solver
  // - from_public_tests: existing nonzero examples assert returned roots solve pow(r, q, p) == a
  // - frame_condition: V2 does not alter this path
  claim
    <k> nthroot_mod(A:Int, N:Int, P:Int, AR:Bool) => nonzeroResult(A, N, P, AR) ... </k>
    requires N =/=Int 2 andBool nthResidue(A, N, P) andBool isPrime(P)
     andBool notBool (N >Int 0 andBool P >Int 0 andBool A modInt P ==Int 0)
    [all-path]
endmodule
