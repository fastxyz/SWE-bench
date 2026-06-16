requires "mini-python-partitions.k"

module PARTITIONS-SNAPSHOT-SPEC-SYNTAX
  imports MINI-PARTITIONS-SYNTAX
  imports BOOL-SYNTAX

  syntax Int ::= length(List) [function]
  syntax Bool ::= idsAreRange(Int, List) [function]
                | sizeIdsAreRange(Int, List) [function]
                | heapMatches(Int, List, List, Map) [function]
                | sizeHeapMatches(Int, List, List, Map) [function]
endmodule

module PARTITIONS-SNAPSHOT-VERIFICATION
  imports PARTITIONS-SNAPSHOT-SPEC-SYNTAX
  imports MINI-PARTITIONS
  imports INT
  imports BOOL
  imports MAP
  imports LIST
  imports K-EQUAL

  rule length(.List) => 0
  rule length(ListItem(_) REST:List) => 1 +Int length(REST)

  rule idsAreRange(_:Int, .List) => true
  rule idsAreRange(I:Int, ListItem(I) REST:List)
        => idsAreRange(I +Int 1, REST)
  rule idsAreRange(_:Int, _:List) => false [owise]

  rule sizeIdsAreRange(_:Int, .List) => true
  rule sizeIdsAreRange(I:Int, ListItem(out(_:Int, I)) REST:List)
        => sizeIdsAreRange(I +Int 1, REST)
  rule sizeIdsAreRange(_:Int, _:List) => false [owise]

  rule heapMatches(_:Int, .List, .List, _:Map) => true
  rule heapMatches(I:Int, ListItem(I) IDS:List, ListItem(M:Map) STATES:List, H:Map)
        => { H [ I ] #Equals M } andBool heapMatches(I +Int 1, IDS, STATES, H)
  rule heapMatches(_:Int, _:List, _:List, _:Map) => false [owise]

  rule sizeHeapMatches(_:Int, .List, .List, _:Map) => true
  rule sizeHeapMatches(I:Int, ListItem(out(S:Int, I)) IDS:List,
                       ListItem(state(S, M:Map)) STATES:List, H:Map)
        => { H [ I ] #Equals M } andBool sizeHeapMatches(I +Int 1, IDS, STATES, H)
  rule sizeHeapMatches(_:Int, _:List, _:List, _:Map) => false [owise]
endmodule

module PARTITIONS-SNAPSHOT-SPEC
  imports PARTITIONS-SNAPSHOT-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "list(partitions()) will give an apparently wrong result"
  //   => retained outputs must be stable snapshots, not aliases of one mutable dict.
  // - from_prompt: "copy the dictionary before yielding it"
  //   => yield-boundary copy is the intended repair.
  // - from_docstring: "Each partition is represented as a dictionary"
  //   => each output id denotes a dict-like map with the yielded partition contents.
  // - from_code: STATES abstracts the unchanged integer-partition enumeration sequence;
  //   the proof is about the public snapshot boundary, not a re-proof of enumeration.
  claim
    <k> collect(STATES:List) => .K ... </k>
    <heap> .Map => HEAP:Map </heap>
    <nextId> START:Int => START +Int length(STATES) </nextId>
    <out> .List => IDS:List </out>
    requires START >=Int 0
    ensures idsAreRange(START, IDS)
      andBool heapMatches(START, IDS, STATES, HEAP)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docstring: "when True then (M, P) is returned where M is the sum
  //   of the multiplicities and P is the generated partition"
  //   => the P component of size=True output has the same snapshot obligation.
  // - from_prompt: the confusing reuse applies to any yielded partition dictionary.
  claim
    <k> collectSize(STATES:List) => .K ... </k>
    <heap> .Map => HEAP:Map </heap>
    <nextId> START:Int => START +Int length(STATES) </nextId>
    <out> .List => OUTS:List </out>
    requires START >=Int 0
    ensures sizeIdsAreRange(START, OUTS)
      andBool sizeHeapMatches(START, OUTS, STATES, HEAP)
    [all-path]
endmodule
