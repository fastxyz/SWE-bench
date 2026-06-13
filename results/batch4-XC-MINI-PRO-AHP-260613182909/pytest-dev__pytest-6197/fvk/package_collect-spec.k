// package_collect-spec.k -- claims for the side-effect invariant of
// _pytest.python.Package.collect() (V1 fix for #6197).
//
// CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP) -- toolchain not run here.
//
// Program variables (lowercase) vs. logical variables (uppercase):
//   mounted, yielded, i, n   are program variables;
//   M, Y, I, N               are symbolic logical values.
//
// The loop body is exactly the abstracted per-node action:
//     mounted = 1 ; yielded = yielded + 1 ; i = i + 1
// run `n` times. `mounted = 1` is idempotent, modelling _mount_obj_if_needed().

requires "package_collect.k"

module PACKAGE-COLLECT-SPEC-SYNTAX
  imports PACKAGE-COLLECT-SYNTAX
endmodule

module VERIFICATION
  imports PACKAGE-COLLECT-SPEC-SYNTAX
  imports PACKAGE-COLLECT
  imports MAP-SYMBOLIC
  imports K-EQUAL
endmodule

module PACKAGE-COLLECT-SPEC
  imports VERIFICATION

  // ----------------------------------------------------------------------
  // (LOOP) -- loop circularity (the coinduction hypothesis for its own loop).
  //
  // From a generic mid-loop state (mounted=M in {0,1}, yielded=Y, i=I) with
  // I <= N, running the loop to completion:
  //   * advances i to N,
  //   * adds (N - I) to yielded,
  //   * leaves mounted = 1 iff it was already 1 OR at least one iteration ran
  //     (i.e. I < N); otherwise mounted stays 0.
  // ----------------------------------------------------------------------
  claim
    <k> while ( i < n ) { mounted = 1 ; yielded = yielded + 1 ; i = i + 1 } => .K ... </k>
    <store>
      mounted |-> (M:Int => ?Mf:Int)
      yielded |-> (Y:Int => Y +Int (N -Int I))
      i       |-> (I:Int => N)
      n       |-> N:Int
    </store>
    requires I <=Int N
     andBool (M ==Int 0 orBool M ==Int 1)
    ensures  (?Mf ==Int 1 andBool ((M ==Int 1) orBool (I <Int N)))
      orBool (?Mf ==Int 0 andBool (M ==Int 0) andBool (I ==Int N))
    [all-path]

  // ----------------------------------------------------------------------
  // (COLLECT) -- function contract for the whole abstracted method.
  //
  // Start in the entry state (mounted=0, yielded=0, i=0); the model runs to
  //   yielded = N        (every collectible node is produced), and
  //   mounted = 1  iff  N >= 1.
  //
  // SAFETY COROLLARY (the #6197 fix, formally):
  //   N = 0  ==>  mounted = 0  -- when the package contributes nothing, its
  //   __init__.py is never imported.
  // MARKER COROLLARY (keeps test_skip_package passing):
  //   N >= 1 ==>  mounted = 1  -- whenever the package contributes a node, the
  //   mount (hence own_markers population) has happened, and -- because it is
  //   placed before the yield -- it happened before any descendant test runs.
  // ----------------------------------------------------------------------
  claim
    <k> while ( i < n ) { mounted = 1 ; yielded = yielded + 1 ; i = i + 1 } => .K ... </k>
    <store>
      mounted |-> (0 => ?Mf:Int)
      yielded |-> (0 => N)
      i       |-> (0 => N)
      n       |-> N:Int
    </store>
    requires N >=Int 0
    ensures  (?Mf ==Int 1 andBool N >=Int 1)
      orBool (?Mf ==Int 0 andBool N ==Int 0)
    [all-path]
endmodule
