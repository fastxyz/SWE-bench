module MINI-QUATERNION-SYNTAX
  imports INT-SYNTAX
  imports ID-SYNTAX

  syntax AExp ::= Id
                | Int
                | "(" AExp ")"                  [bracket]
                > AExp "^2"                     [function]
                > AExp "*" AExp                 [left]
                > AExp "+" AExp                 [left]
                | AExp "-" AExp                 [left]
                | "inv" "(" AExp ")"

  syntax Quat ::= "quat" "(" AExp "," AExp "," AExp "," AExp ")"
  syntax Vec3 ::= "vec3" "(" AExp "," AExp "," AExp ")"
  syntax Mat3 ::= "mat3" "(" AExp "," AExp "," AExp ","
                           AExp "," AExp "," AExp ","
                           AExp "," AExp "," AExp ")"
  syntax Mat4 ::= "mat4" "(" AExp "," AExp "," AExp "," AExp ","
                           AExp "," AExp "," AExp "," AExp ","
                           AExp "," AExp "," AExp "," AExp ","
                           AExp "," AExp "," AExp "," AExp ")"

  syntax Mat3 ::= "toRotationMatrix3" "(" Quat ")" [function]
  syntax Mat4 ::= "toRotationMatrix4" "(" Quat "," Vec3 ")" [function]
                | "mat4From3" "(" Mat3 "," Vec3 ")" [function]
  syntax Vec3 ::= "applyMat3" "(" Mat3 "," Vec3 ")" [function]
                | "hamiltonRotate" "(" Quat "," Vec3 ")" [function]
endmodule

module MINI-QUATERNION
  imports MINI-QUATERNION-SYNTAX

  configuration <k> $PGM:K </k>

  syntax AExp ::= "norm2" "(" Quat ")" [function]
  rule norm2(quat(A, B, C, D)) => A^2 + B^2 + C^2 + D^2

  rule toRotationMatrix3(quat(A, B, C, D)) =>
    mat3(
      1 - 2 * (inv(norm2(quat(A, B, C, D))) * (C^2 + D^2)),
      2 * (inv(norm2(quat(A, B, C, D))) * (B*C - D*A)),
      2 * (inv(norm2(quat(A, B, C, D))) * (B*D + C*A)),
      2 * (inv(norm2(quat(A, B, C, D))) * (B*C + D*A)),
      1 - 2 * (inv(norm2(quat(A, B, C, D))) * (B^2 + D^2)),
      2 * (inv(norm2(quat(A, B, C, D))) * (C*D - B*A)),
      2 * (inv(norm2(quat(A, B, C, D))) * (B*D - C*A)),
      2 * (inv(norm2(quat(A, B, C, D))) * (C*D + B*A)),
      1 - 2 * (inv(norm2(quat(A, B, C, D))) * (B^2 + C^2))
    )

  rule toRotationMatrix4(Q:Quat, vec3(X, Y, Z)) =>
    mat4From3(toRotationMatrix3(Q), vec3(X, Y, Z))

  rule mat4From3(
    mat3(M00, M01, M02, M10, M11, M12, M20, M21, M22),
    vec3(X, Y, Z)) =>
    mat4(M00, M01, M02, X - X*M00 - Y*M01 - Z*M02,
         M10, M11, M12, Y - X*M10 - Y*M11 - Z*M12,
         M20, M21, M22, Z - X*M20 - Y*M21 - Z*M22,
         0, 0, 0, 1)

  rule applyMat3(
    mat3(M00, M01, M02, M10, M11, M12, M20, M21, M22),
    vec3(X, Y, Z)) =>
    vec3(M00*X + M01*Y + M02*Z,
         M10*X + M11*Y + M12*Z,
         M20*X + M21*Y + M22*Z)

  rule hamiltonRotate(quat(A, B, C, D), vec3(X, Y, Z)) =>
    vec3(inv(norm2(quat(A, B, C, D))) *
           ((A^2 + B^2 - C^2 - D^2)*X + 2 * ((B*C - A*D)*Y) + 2 * ((B*D + A*C)*Z)),
         inv(norm2(quat(A, B, C, D))) *
           (2 * ((B*C + A*D)*X) + (A^2 - B^2 + C^2 - D^2)*Y + 2 * ((C*D - A*B)*Z)),
         inv(norm2(quat(A, B, C, D))) *
           (2 * ((B*D - A*C)*X) + 2 * ((C*D + A*B)*Y) + (A^2 - B^2 - C^2 + D^2)*Z))
endmodule
