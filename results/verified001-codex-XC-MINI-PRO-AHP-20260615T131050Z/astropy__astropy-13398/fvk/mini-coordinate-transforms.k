module MINI-COORDINATE-TRANSFORMS-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Loc ::= noLoc | center | loc(Int)
  syntax Time ::= none | time(Int) | chooseTime(Time, Time) [function]
  syntax ObsKind ::= altaz | hadec
  syntax Refrac ::= noRefrac | refrac
  syntax Frame ::= itrs(Loc, Time)
                 | observed(ObsKind, Loc, Time, Refrac)
                 | cirs(Loc, Time)
                 | tete(Loc, Time)
  syntax Vec ::= vec(Int, Int, Int)
               | rotate(ObsKind, Loc, Vec) [function]
               | invRotate(ObsKind, Loc, Vec) [function]
               | selfITRS(Loc, Loc, Time, Time, Vec) [function]
               | toCIRS(Time, Vec) [function]
               | fromCIRS(Time, Vec) [function]
               | addLocation(Loc, Vec) [function]
               | refract(ObsKind, Loc, Time, Vec) [function]
               | unrefract(ObsKind, Loc, Time, Vec) [function]
  syntax Result ::= coord(Frame, Vec)
                  | errNoLocation
                  | errNoObstime
  syntax Cmd ::= itrsToObserved(Frame, Frame, Vec)
               | observedToITRS(Frame, Frame, Vec)
               | itrsToIntermediate(Frame, Frame, Vec)
               | intermediateToITRS(Frame, Frame, Vec)
               | earthLocation(Frame, Vec)
  syntax KResult ::= Result
endmodule

module MINI-COORDINATE-TRANSFORMS
  imports MINI-COORDINATE-TRANSFORMS-SYNTAX
  imports BOOL
  imports K-EQUAL

  configuration <k> $PGM:Cmd </k>

  rule chooseTime(none, T) => T
  rule chooseTime(TO, T) => TO requires TO =/=K none

  rule <k> itrsToObserved(IF, observed(K, noLoc, TO, R), V) => errNoLocation </k>
  rule <k> observedToITRS(observed(K, noLoc, TO, R), OF, V) => errNoLocation </k>

  rule <k> itrsToObserved(itrs(L, T), observed(K, L, TO, noRefrac), V)
        => coord(observed(K, L, TO, noRefrac), rotate(K, L, V)) </k>

  rule <k> itrsToObserved(itrs(L1, T), observed(K, L2, TO, noRefrac), V)
        => coord(observed(K, L2, TO, noRefrac),
                 rotate(K, L2, selfITRS(L1, L2, T, chooseTime(TO, T), V))) </k>
    requires L1 =/=K L2 andBool L2 =/=K noLoc

  rule <k> itrsToObserved(itrs(L, T), observed(K, L, none, refrac), V)
        => errNoObstime </k>

  rule <k> itrsToObserved(itrs(L, T), observed(K, L, TO, refrac), V)
        => coord(observed(K, L, TO, refrac),
                 refract(K, L, TO, toCIRS(TO, V))) </k>
    requires TO =/=K none

  rule <k> itrsToObserved(itrs(L1, T), observed(K, L2, none, refrac), V)
        => itrsToObserved(itrs(L2, T), observed(K, L2, none, refrac),
                          selfITRS(L1, L2, T, T, V)) </k>
    requires L1 =/=K L2 andBool L2 =/=K noLoc

  rule <k> itrsToObserved(itrs(L1, T), observed(K, L2, TO, refrac), V)
        => itrsToObserved(itrs(L2, TO), observed(K, L2, TO, refrac),
                          selfITRS(L1, L2, T, TO, V)) </k>
    requires L1 =/=K L2 andBool L2 =/=K noLoc andBool TO =/=K none

  rule <k> observedToITRS(observed(K, L, TO, noRefrac), itrs(L, TOut), V)
        => coord(itrs(L, TOut), invRotate(K, L, V)) </k>
    requires L =/=K noLoc

  rule <k> observedToITRS(observed(K, L1, TO, noRefrac), itrs(L2, TOut), V)
        => coord(itrs(L2, TOut),
                 selfITRS(L1, L2, TOut, TOut, invRotate(K, L1, V))) </k>
    requires L1 =/=K L2 andBool L1 =/=K noLoc

  rule <k> observedToITRS(observed(K, L, none, refrac), itrs(L2, TOut), V)
        => errNoObstime </k>
    requires L =/=K noLoc

  rule <k> observedToITRS(observed(K, L, TO, refrac), itrs(L, TOut), V)
        => coord(itrs(L, TOut), fromCIRS(TO, unrefract(K, L, TO, V))) </k>
    requires L =/=K noLoc andBool TO =/=K none

  rule <k> observedToITRS(observed(K, L1, TO, refrac), itrs(L2, TOut), V)
        => coord(itrs(L2, TOut),
                 selfITRS(L1, L2, TOut, TOut,
                          fromCIRS(TO, unrefract(K, L1, TO, V)))) </k>
    requires L1 =/=K L2 andBool L1 =/=K noLoc andBool TO =/=K none

  rule <k> itrsToIntermediate(itrs(L, T), cirs(L2, T2), V)
        => coord(cirs(L, T), toCIRS(T, V)) </k>

  rule <k> itrsToIntermediate(itrs(L, T), tete(L2, T2), V)
        => coord(tete(L, T), toCIRS(T, V)) </k>

  rule <k> intermediateToITRS(cirs(L1, T1), itrs(L, T), V)
        => coord(itrs(L, T), fromCIRS(T, V)) </k>

  rule <k> intermediateToITRS(tete(L1, T1), itrs(L, T), V)
        => coord(itrs(L, T), fromCIRS(T, V)) </k>

  rule <k> earthLocation(itrs(L, T), V) => coord(itrs(center, none), addLocation(L, V)) </k>
endmodule
