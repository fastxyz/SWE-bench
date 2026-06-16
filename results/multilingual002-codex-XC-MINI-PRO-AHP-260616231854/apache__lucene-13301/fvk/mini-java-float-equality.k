module MINI-JAVA-FLOAT-EQUALITY-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax JFloat ::= f(Int)
  syntax JDouble ::= d(Int)

  syntax GeoObj ::=
      xyPoint(JFloat, JFloat)
    | xyCircle(JFloat, JFloat, JFloat)
    | xyRectangle(JFloat, JFloat, JFloat, JFloat)
    | point(JDouble, JDouble)
    | circle(JDouble, JDouble, JDouble)
    | rectangle2D(JDouble, JDouble, JDouble, JDouble)

  syntax Exp ::= Bool | Int
  syntax Bool ::= equals(GeoObj, GeoObj) [function]
                | fCompare(JFloat, JFloat) [function]
                | dCompare(JDouble, JDouble) [function]
  syntax Int ::= hash(GeoObj) [function]
               | fHash(JFloat) [function]
               | dHash(JDouble) [function]

  syntax KResult ::= Bool | Int
endmodule

module MINI-JAVA-FLOAT-EQUALITY
  imports MINI-JAVA-FLOAT-EQUALITY-SYNTAX
  imports INT
  imports BOOL

  configuration <k> $PGM:Exp </k>

  // The Int inside f(...) and d(...) is the hash-relevant canonical bit key.
  // For finite values this keeps -0.0 and +0.0 distinct, matching
  // Float/Double.compare and Float/Double.hashCode for the audited property.
  rule fCompare(f(A), f(B)) => A ==Int B
  rule dCompare(d(A), d(B)) => A ==Int B
  rule fHash(f(A)) => A
  rule dHash(d(A)) => A

  rule equals(xyPoint(X1, Y1), xyPoint(X2, Y2))
        => fCompare(X1, X2) andBool fCompare(Y1, Y2)
  rule equals(xyCircle(X1, Y1, R1), xyCircle(X2, Y2, R2))
        => fCompare(X1, X2) andBool fCompare(Y1, Y2) andBool fCompare(R1, R2)
  rule equals(xyRectangle(MinX1, MaxX1, MinY1, MaxY1),
              xyRectangle(MinX2, MaxX2, MinY2, MaxY2))
        => fCompare(MinX1, MinX2) andBool fCompare(MaxX1, MaxX2)
           andBool fCompare(MinY1, MinY2) andBool fCompare(MaxY1, MaxY2)

  rule equals(point(Lat1, Lon1), point(Lat2, Lon2))
        => dCompare(Lat1, Lat2) andBool dCompare(Lon1, Lon2)
  rule equals(circle(Lat1, Lon1, R1), circle(Lat2, Lon2, R2))
        => dCompare(Lat1, Lat2) andBool dCompare(Lon1, Lon2) andBool dCompare(R1, R2)
  rule equals(rectangle2D(MinX1, MaxX1, MinY1, MaxY1),
              rectangle2D(MinX2, MaxX2, MinY2, MaxY2))
        => dCompare(MinX1, MinX2) andBool dCompare(MaxX1, MaxX2)
           andBool dCompare(MinY1, MinY2) andBool dCompare(MaxY1, MaxY2)

  rule hash(xyPoint(X, Y))
        => 31 *Int fHash(X) +Int fHash(Y)
  rule hash(xyCircle(X, Y, R))
        => 31 *Int (31 *Int fHash(X) +Int fHash(Y)) +Int fHash(R)
  rule hash(xyRectangle(MinX, MaxX, MinY, MaxY))
        => 31 *Int (31 *Int (31 *Int fHash(MinX) +Int fHash(MinY)) +Int fHash(MaxX))
           +Int fHash(MaxY)

  rule hash(point(Lat, Lon))
        => 31 *Int dHash(Lat) +Int dHash(Lon)
  rule hash(circle(Lat, Lon, R))
        => 31 *Int (31 *Int dHash(Lat) +Int dHash(Lon)) +Int dHash(R)
  rule hash(rectangle2D(MinX, MaxX, MinY, MaxY))
        => 31 *Int (31 *Int (31 *Int (31 *Int 1 +Int dHash(MinX)) +Int dHash(MaxX))
           +Int dHash(MinY)) +Int dHash(MaxY)
endmodule
