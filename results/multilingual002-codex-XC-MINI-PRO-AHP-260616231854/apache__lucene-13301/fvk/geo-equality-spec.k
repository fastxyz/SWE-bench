requires "mini-java-float-equality.k"

module GEO-EQUALITY-SPEC
  imports MINI-JAVA-FLOAT-EQUALITY

  // SPEC-PROVENANCE:
  // - from_prompt: "when comparing float values using the == operation, -0.0 is equal to 0.0,
  //   but their hashcode is different" => equals/hashCode contract must not equate signed zeros
  //   while preserving signed-zero-sensitive hashes.
  // - from_code: XYPoint/XYCircle/Point/Circle/Rectangle2D hashCode methods use
  //   Float.hashCode, Double.hashCode, or Objects.hash over boxed doubles.
  // - from_default_domain: Java equals/hashCode contract requires equal objects to have equal hashes.

  claim <k> equals(xyPoint(f(X1), f(Y1)), xyPoint(f(X2), f(Y2))) => true ... </k>
    requires X1 ==Int X2 andBool Y1 ==Int Y2
    [all-path]

  claim <k> hash(xyPoint(f(X1), f(Y1))) ==Int hash(xyPoint(f(X2), f(Y2))) => true ... </k>
    requires equals(xyPoint(f(X1), f(Y1)), xyPoint(f(X2), f(Y2))) ==Bool true
    [all-path]

  claim <k> equals(xyCircle(f(X1), f(Y1), f(R1)), xyCircle(f(X2), f(Y2), f(R2))) => true ... </k>
    requires X1 ==Int X2 andBool Y1 ==Int Y2 andBool R1 ==Int R2
    [all-path]

  claim <k> hash(xyCircle(f(X1), f(Y1), f(R1))) ==Int hash(xyCircle(f(X2), f(Y2), f(R2))) => true ... </k>
    requires equals(xyCircle(f(X1), f(Y1), f(R1)), xyCircle(f(X2), f(Y2), f(R2))) ==Bool true
    [all-path]

  claim <k> hash(xyRectangle(f(A1), f(B1), f(C1), f(D1))) ==Int hash(xyRectangle(f(A2), f(B2), f(C2), f(D2))) => true ... </k>
    requires equals(xyRectangle(f(A1), f(B1), f(C1), f(D1)),
                    xyRectangle(f(A2), f(B2), f(C2), f(D2))) ==Bool true
    [all-path]

  claim <k> hash(point(d(Lat1), d(Lon1))) ==Int hash(point(d(Lat2), d(Lon2))) => true ... </k>
    requires equals(point(d(Lat1), d(Lon1)), point(d(Lat2), d(Lon2))) ==Bool true
    [all-path]

  claim <k> hash(circle(d(Lat1), d(Lon1), d(R1))) ==Int hash(circle(d(Lat2), d(Lon2), d(R2))) => true ... </k>
    requires equals(circle(d(Lat1), d(Lon1), d(R1)), circle(d(Lat2), d(Lon2), d(R2))) ==Bool true
    [all-path]

  claim <k> hash(rectangle2D(d(A1), d(B1), d(C1), d(D1))) ==Int hash(rectangle2D(d(A2), d(B2), d(C2), d(D2))) => true ... </k>
    requires equals(rectangle2D(d(A1), d(B1), d(C1), d(D1)),
                    rectangle2D(d(A2), d(B2), d(C2), d(D2))) ==Bool true
    [all-path]

  claim <k> equals(xyPoint(f(-2147483648), f(Y)), xyPoint(f(0), f(Y))) => false ... </k>
    [all-path]

  claim <k> equals(point(d(-9223372036854775808), d(Y)), point(d(0), d(Y))) => false ... </k>
    [all-path]
endmodule
