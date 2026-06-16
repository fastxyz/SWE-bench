requires "mini-evalf.k"

module EVALF-FALLBACK-SPEC
  imports MINI-EVALF

  // SPEC-PROVENANCE:
  // - INT-1 prompt: "UnboundLocalError in evalf" for Mul(Max(0, y), x)
  //   => symbolic fallback components must not reach an uninitialized precision.
  // - INT-2 prompt: "else: raise NotImplementedError" is proposed as a fix
  //   => non-numeric nonzero components leave the numeric fallback path.
  // - INT-3 evalf.py tuple comment: re/im are mpf tuples or None for exact zeros
  //   => successful fallback tuples contain only numeric values or exact-zero sentinels.
  claim <k> fallback(sym, zero) => notImplemented </k> [all-path]

  // SPEC-PROVENANCE:
  // - INT-1/INT-2/INT-3, symmetric imaginary-component case.
  claim <k> fallback(zero, sym) => notImplemented </k> [all-path]

  // SPEC-PROVENANCE:
  // - INT-3 evalf.py tuple contract
  //   => exact-zero real plus numeric imaginary is a well-formed tuple.
  claim <k> fallback(zero, num) => tuple(noneVal, mpfVal, nonePrec, somePrec) </k> [all-path]

  // SPEC-PROVENANCE:
  // - INT-3 evalf.py tuple contract
  //   => numeric real plus exact-zero imaginary is a well-formed tuple.
  claim <k> fallback(num, zero) => tuple(mpfVal, noneVal, somePrec, nonePrec) </k> [all-path]

  // SPEC-PROVENANCE:
  // - INT-3 evalf.py tuple contract
  //   => fully numeric complex fallback is a well-formed tuple.
  claim <k> fallback(num, num) => tuple(mpfVal, mpfVal, somePrec, somePrec) </k> [all-path]

  // SPEC-PROVENANCE:
  // - INT-3 evalf.py tuple contract
  //   => exact-zero real and imaginary components remain exact-zero sentinels.
  claim <k> fallback(zero, zero) => tuple(noneVal, noneVal, nonePrec, nonePrec) </k> [all-path]
endmodule
