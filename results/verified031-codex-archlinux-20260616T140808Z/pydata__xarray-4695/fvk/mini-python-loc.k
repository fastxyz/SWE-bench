// Minimal dispatch semantics for pydata__xarray-4695.
// Constructed, not machine-checked.
//
// This is not a full Python or xarray semantics. It models only the argument
// binding distinction that the issue depends on:
//   - positional indexer mapping: selPos(M)
//   - keyword-unpacked mapping:   selKw(M)

module MINI-PYTHON-LOC-SYNTAX
  imports MAP-SYNTAX
  imports STRING-SYNTAX
  imports BOOL-SYNTAX

  syntax MethodState ::= "exact" | "nearest" | "pad" | "ffill" | "backfill" | "bfill"
                       | badMethod(String)

  syntax Call ::= locGet(Map)
                | helperSelect(String, String)
                | legacyLocGet(Map)
                | selPos(Map)
                | selKw(Map)

  syntax Outcome ::= dispatched(Map, MethodState)
                   | invalidFillMethod(String)

  syntax KResult ::= Outcome
endmodule

module MINI-PYTHON-LOC
  imports MINI-PYTHON-LOC-SYNTAX
  imports MAP
  imports STRING
  imports BOOL

  configuration <k> $PGM:Call </k>

  syntax Bool ::= validFillMethod(String) [function]
  rule validFillMethod("nearest") => true
  rule validFillMethod("pad") => true
  rule validFillMethod("ffill") => true
  rule validFillMethod("backfill") => true
  rule validFillMethod("bfill") => true
  rule validFillMethod(_) => false [owise]

  // Fixed .loc path: the entire mapping is the positional `indexers` argument.
  rule <k> locGet(M:Map) => selPos(M) ... </k>

  // Fixed helper path: a dynamic dimension name is data inside the indexer map.
  rule <k> helperSelect(D:String, V:String) => selPos(D |-> V) ... </k>

  // Legacy path: keyword unpacking lets keys collide with reserved parameters.
  rule <k> legacyLocGet(M:Map) => selKw(M) ... </k>

  // Positional mapping dispatch preserves every key as an indexer and leaves
  // exact label matching selected.
  rule <k> selPos(M:Map) => dispatched(M, exact) ... </k>

  // Concrete public counterexample: "method" is bound as the reserved fill
  // method option, so label "a" becomes an invalid fill method.
  rule <k> selKw("dim1" |-> "x" "method" |-> "a")
        => invalidFillMethod("a")
       ... </k>
       requires notBool validFillMethod("a")
endmodule
