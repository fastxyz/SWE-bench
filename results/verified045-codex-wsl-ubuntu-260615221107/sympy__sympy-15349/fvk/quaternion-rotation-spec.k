requires "mini-quaternion.k"

module MINI-QUATERNION-SPEC
  imports MINI-QUATERNION

  // SPEC-PROVENANCE:
  // - from_prompt: "One of the sin(x) functions should be negative" =>
  //   x-axis quaternion must have antisymmetric sine entries.
  // - from_docs_or_tests: to_rotation_matrix doc says "equivalent rotation
  //   transformation matrix" and rotate_point uses q * point * conjugate(q) =>
  //   active Hamilton rotation convention.
  // - from_code: _generic_mul supplies the Hamilton product used to derive the
  //   independent reference vector formula.
  // - conflicts: visible q=(1,2,3,4) tests expect the legacy plus-sign M12;
  //   marked SUSPECT in FINDINGS.md.
  claim
    <k> toRotationMatrix3(quat(A, B, C, D)) =>
      mat3(
        1 - 2 * (inv(norm2(quat(A, B, C, D))) * (C^2 + D^2)),
        2 * (inv(norm2(quat(A, B, C, D))) * (B*C - D*A)),
        2 * (inv(norm2(quat(A, B, C, D))) * (B*D + C*A)),
        2 * (inv(norm2(quat(A, B, C, D))) * (B*C + D*A)),
        1 - 2 * (inv(norm2(quat(A, B, C, D))) * (B^2 + D^2)),
        2 * (inv(norm2(quat(A, B, C, D))) * (C*D - B*A)),
        2 * (inv(norm2(quat(A, B, C, D))) * (B*D - C*A)),
        2 * (inv(norm2(quat(A, B, C, D))) * (C*D + B*A)),
        1 - 2 * (inv(norm2(quat(A, B, C, D))) * (B^2 + C^2)))
    </k>
    requires norm2(quat(A, B, C, D)) =/=K 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: rotate_point active convention =>
  //   applying the matrix to a point equals q * point * conjugate(q).
  claim
    <k> applyMat3(toRotationMatrix3(quat(A, B, C, D)), vec3(X, Y, Z)) =>
        hamiltonRotate(quat(A, B, C, D), vec3(X, Y, Z))
    </k>
    requires norm2(quat(A, B, C, D)) =/=K 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: reported x-axis quaternion =>
  //   M12 is negative and M21 is positive after trig simplification.
  // C2 abbreviates cos(t/2); S2 abbreviates sin(t/2). The trig identities are
  // recorded in PROOF_OBLIGATIONS.md rather than encoded as executable K rules.
  claim
    <k> toRotationMatrix3(quat(C2, S2, 0, 0)) =>
      mat3(1, 0, 0,
           0, C2^2 - S2^2, 0 - 2 * (S2*C2),
           0, 2 * (S2*C2), C2^2 - S2^2)
    </k>
    requires C2^2 + S2^2 =/=K 0
    [all-path]
endmodule
