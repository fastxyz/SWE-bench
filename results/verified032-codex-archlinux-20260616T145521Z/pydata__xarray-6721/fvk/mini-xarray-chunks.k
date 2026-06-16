// Constructed, not machine-checked.
// Mini semantics fragment for the xarray chunk metadata accessors audited in
// pydata__xarray-6721. This is an abstract model of the relevant Python
// behavior, not a full Python semantics.

module MINI-XARRAY-CHUNKS-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports LIST-SYNTAX
  imports MAP-SYNTAX

  syntax ChunkOpt ::= "NoChunks"
                    | "SomeChunks" "(" List ")"

  // Var(DIMS, CHUNKS, MATERIALIZED) models the only state relevant to the
  // issue: dimension names, _data.chunks metadata, and whether data loading
  // has happened.
  syntax Var ::= "Var" "(" List "," ChunkOpt "," Bool ")"
  syntax Vars ::= ".Vars"
                | Var Vars

  syntax Cmd ::= "chunks" "(" Var ")"
               | "chunksizes" "(" Var ")"
               | "getChunksizes" "(" Vars ")"

  syntax KResult ::= ChunkOpt | Map | Bool
endmodule

module MINI-XARRAY-CHUNKS
  imports MINI-XARRAY-CHUNKS-SYNTAX
  imports BOOL
  imports INT
  imports LIST
  imports MAP

  configuration
    <k> $PGM:Cmd </k>
    <loaded> false </loaded>

  syntax Map ::= zipDimsChunks(List, List) [function]
  syntax Map ::= mergeChunkMaps(Map, Map) [function]
  syntax Bool ::= consistentWith(Map, Map) [function]
  syntax Map ::= chunksizesOf(Var) [function]
  syntax Map ::= getChunksizesValue(Vars) [function]

  rule chunksizesOf(Var(DIMS, NoChunks, LOADED)) => .Map
  rule chunksizesOf(Var(DIMS, SomeChunks(CS), LOADED)) => zipDimsChunks(DIMS, CS)

  rule getChunksizesValue(.Vars) => .Map
  rule getChunksizesValue(V VARS) => mergeChunkMaps(chunksizesOf(V), getChunksizesValue(VARS))

  // V1 metadata access rules. None of these rules changes <loaded>.
  rule <k> chunks(Var(DIMS, C, LOADED)) => C </k>
  rule <k> chunksizes(V) => chunksizesOf(V) </k>
  rule <k> getChunksizes(VARS) => getChunksizesValue(VARS) </k>
endmodule
