requires "verification.k"

module NTHROOT-MOD-OBLIGATIONS
  imports VERIFICATION

  // OPEN-OBLIGATION PRIME-ZERO-UNIQUE:
  // For prime P and positive N, if X**N == 0 mod P, then X == 0 mod P.
  // This is a standard number-theory theorem, but the mini semantics leaves
  // isPrime and powMod abstract, so a bundled kprove run is not expected to
  // discharge it without an added prime divisibility theory.
  // SPEC-PROVENANCE:
  // - from_prompt: zero-residue root for x**n = a mod p
  // - from_default_domain: Euclid's lemma for prime divisibility
  claim
    <k> .K => .K </k>
    requires P >Int 1 andBool N >Int 0 andBool isPrime(P)
     andBool A modInt P ==Int 0 andBool powMod(X:Int, N, P) ==Int A modInt P
    ensures X modInt P ==Int 0
    [all-path]
endmodule
