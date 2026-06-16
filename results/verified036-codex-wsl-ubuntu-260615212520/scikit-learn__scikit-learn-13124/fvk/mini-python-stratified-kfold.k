module MINI-PYTHON-STRATIFIED-KFOLD-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX

  syntax Seed ::= intSeed(Int)
                | noneSeed(Int)           // global RNG, next-draw-index
                | rngObj(Int, Int)        // rngObj(seed, next-draw-index)

  syntax Rng ::= noRng
               | rng(Int, Int)            // rng(seed, next-draw-index)

  syntax Counts ::= ".Counts"
                  | count(Int) Counts      [right]

  syntax Perms ::= ".Perms"
                 | draw(Int, Int, Int) Perms [right]
                 | ordered(Int) Perms        [right]

  syntax Perms ::= makeTestFolds(Bool, Seed, Counts)       [function]
                 | legacyMakeTestFolds(Bool, Seed, Counts) [function]
                 | assignPerms(Bool, Rng, Counts)          [function]
                 | legacyAssignPerms(Bool, Seed, Counts)   [function]

  syntax Rng ::= checkRandomState(Bool, Seed) [function]
endmodule

module MINI-PYTHON-STRATIFIED-KFOLD
  imports MINI-PYTHON-STRATIFIED-KFOLD-SYNTAX
  imports INT
  imports BOOL

  // V1 model: check_random_state is called once for the whole split call when
  // shuffle=True. An integer seed creates one stream at draw index 0; a
  // RandomState object is returned as itself.
  rule checkRandomState(true, intSeed(S:Int)) => rng(S, 0)
  rule checkRandomState(true, rngObj(S:Int, D:Int)) => rng(S, D)
  rule checkRandomState(true, noneSeed(D:Int)) => rng(-1, D)
  rule checkRandomState(false, _:Seed) => noRng

  rule makeTestFolds(SHUFFLE:Bool, SEED:Seed, COUNTS:Counts)
    => assignPerms(SHUFFLE, checkRandomState(SHUFFLE, SEED), COUNTS)

  rule assignPerms(true, rng(S:Int, D:Int), .Counts) => .Perms
  rule assignPerms(true, rng(S:Int, D:Int), count(N:Int) CS:Counts)
    => draw(S, D, N) assignPerms(true, rng(S, D +Int 1), CS)
    requires N >=Int 0

  rule assignPerms(false, noRng, .Counts) => .Perms
  rule assignPerms(false, noRng, count(N:Int) CS:Counts)
    => ordered(N) assignPerms(false, noRng, CS)
    requires N >=Int 0

  // Legacy model for the finding: every class receives the integer seed and
  // therefore restarts at draw index 0.
  rule legacyMakeTestFolds(SHUFFLE:Bool, SEED:Seed, COUNTS:Counts)
    => legacyAssignPerms(SHUFFLE, SEED, COUNTS)

  rule legacyAssignPerms(true, intSeed(S:Int), .Counts) => .Perms
  rule legacyAssignPerms(true, intSeed(S:Int), count(N:Int) CS:Counts)
    => draw(S, 0, N) legacyAssignPerms(true, intSeed(S), CS)
    requires N >=Int 0

  rule legacyAssignPerms(false, _:Seed, .Counts) => .Perms
  rule legacyAssignPerms(false, SEED:Seed, count(N:Int) CS:Counts)
    => ordered(N) legacyAssignPerms(false, SEED, CS)
    requires N >=Int 0
endmodule
