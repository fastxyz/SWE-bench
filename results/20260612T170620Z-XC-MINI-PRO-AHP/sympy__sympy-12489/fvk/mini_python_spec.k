// mini_python_spec.k
// ---------------------------------------------------------------------------
// Reachability claims for the Permutation subclassing contract, over the
// mini-Python semantics in mini_python.k.  Constructed, NOT machine-checked.
//
// The class table holds the *modelled* bodies of the methods the fix touches:
//   Permutation._af_new   (classmethod, V1 == fixed: returns Basic_new(cls, perm))
//   Permutation.__new__   (the FIXED constructor cascade)
//   Permutation.mul       (an instance operation, returns self._af_new(...))
//   Permutation.random    (a factory classmethod, returns cls._af_new(...))
//   Sub                   (empty subclass; inherits everything)
// plus a contrast pair PermutationV1 / SubV1 whose __new__ keeps the V1
// identity short-circuit `return a` so the refuted claim can be exhibited.
// ---------------------------------------------------------------------------

requires "mini_python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX
  // program identifiers as tokens, so they are NOT read as K logical variables
  syntax Id ::= "Permutation" [token] | "Sub"  [token] | "Object" [token]
              | "PermutationV1" [token] | "SubV1" [token]
              | "__new__" [token] | "_af_new" [token]
              | "mul" [token] | "random" [token]
              | "perm" [token] | "arg" [token] | "clsp" [token]
              | "other" [token] | "n" [token]
endmodule

module VERIFICATION
  imports MINI-PYTHON
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // predicates used by the modelled __new__ cascade
  syntax Bool ::= isObjV(Val) [function] | isIntV(Val) [function]
  rule isObjV(obj(_,_)) => true
  rule isObjV(_)        => false [owise]
  rule isIntV(_:Int)    => true
  rule isIntV(_)        => false [owise]

  // ---- the class table (passed as <classes>) ----------------------------
  syntax Map ::= "classTable"    [function] | "permMethods" [function]
               | "permMethodsV1" [function]
  rule permMethods =>
       ( _af_new |-> method(cm, perm, ret Basic_new(cls, perm)) )
       ( __new__ |-> methodNew(clsp, arg,
            if isObjV(arg)
              then ( if isinstance(arg, clsp)                 // <-- the FIX
                       then ret arg
                       else ret construct(clsp, arrayForm(arg)) )
              else ( if isIntV(arg)
                       then ret call(clsp, _af_new, rangeList(arg))
                       else ret Basic_new(clsp, arg) ) ) )
       ( mul    |-> method(im, other, ret call(self, _af_new, arrayForm(self))) )
       ( random |-> method(cm, n,     ret call(cls,  _af_new, rangeList(n))) )

  rule permMethodsV1 =>
       ( _af_new |-> method(cm, perm, ret Basic_new(cls, perm)) )
       ( __new__ |-> methodNew(clsp, arg,
            if isObjV(arg)
              then ret arg                                     // <-- V1 identity short-circuit
              else ( if isIntV(arg)
                       then ret call(clsp, _af_new, rangeList(arg))
                       else ret Basic_new(clsp, arg) ) ) )

  rule classTable =>
       ( Permutation   |-> classDef(Object,        permMethods)   )
       ( Sub           |-> classDef(Permutation,   .Map)          )
       ( PermutationV1 |-> classDef(Object,        permMethodsV1) )
       ( SubV1         |-> classDef(PermutationV1, .Map)          )
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // (AFNEW) classmethod called ON A CLASS yields an instance of THAT class.
  //   Holds for C in {Permutation, Sub} (symbolic).
  claim <k> call(cls(C:Id), _af_new, A:List) => obj(C, A) </k>
        <classes> classTable </classes>  [one-path]

  // (AFNEW-INST) classmethod called on an INSTANCE yields type(instance).
  claim <k> call(obj(C:Id, _:List), _af_new, A:List) => obj(C, A) </k>
        <classes> classTable </classes>  [one-path]

  // (ALIAS) module-level `_af_new = Permutation._af_new` stays bound to the
  //   base class -> external callers still get a base Permutation.
  claim <k> call(cls(Permutation), _af_new, A:List) => obj(Permutation, A) </k>
        <classes> classTable </classes>  [one-path]

  // (NEW-ARRAY) C(list) -> instance of C.
  claim <k> construct(cls(C:Id), L:List) => obj(C, L) </k>
        <classes> classTable </classes>  [one-path]

  // (NEW-INT) C(int) -> instance of C  (uses _af_new internally).
  claim <k> construct(cls(C:Id), N:Int) => obj(C, ?_:List) </k>
        <classes> classTable </classes>  [one-path]

  // (NEW-IDENTITY, FIXED) C(perm) -> ALWAYS an instance of C, for every D.
  //   This is the universal postcondition the fix restores.  Discharged by
  //   case split on isSubclass(D,C); the rebuild branch reuses (NEW-ARRAY).
  claim <k> construct(cls(C:Id), obj(D:Id, B:List)) => ?O:Val </k>
        <classes> classTable </classes>
        ensures isinstance(?O, cls(C)) ==K true             [one-path]

  // (OP) instance operation preserves the class of self.
  claim <k> call(obj(C:Id, B:List), mul, X:Val) => ?O:Val </k>
        <classes> classTable </classes>
        ensures classOf(?O) ==K cls(C)                      [one-path]

  // (FACTORY) factory classmethod yields an instance of the class it is on.
  claim <k> call(cls(C:Id), random, N:Int) => ?O:Val </k>
        <classes> classTable </classes>
        ensures classOf(?O) ==K cls(C)                      [one-path]

  // ---------------------------------------------------------------------
  // (NEW-IDENTITY, V1)  -- REFUTED, kept only to exhibit the V1 bug.
  // The same goal over PermutationV1/SubV1 does NOT hold: with C=SubV1 and
  // D=PermutationV1 the body returns obj(PermutationV1,B) and
  //   isinstance(obj(PermutationV1,B), cls(SubV1)) = isSubclass(PermutationV1,SubV1) = false.
  // This claim is therefore NOT provable; see FINDINGS.md F1.
  //
  // claim <k> construct(cls(C:Id), obj(D:Id, B:List)) => ?O:Val </k>
  //       <classes> classTableV1 </classes>
  //       ensures isinstance(?O, cls(C)) ==K true          [one-path]   // FAILS
endmodule
