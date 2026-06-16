requires "mini-python.k"

module PERMUTATION-SUBCLASS-SPEC
  imports MINI-PYTHON
  imports LIST

  // SPEC-PROVENANCE:
  // - from_prompt: "`_af_new` should probably be a `classmethod` with
  //   creating command `Basic.__new__(cls, perm)`" => fast constructor
  //   preserves the called class.
  claim
    <k> afNew(C:Class, A:List) => .K </k>
    <result> noObj => obj(C, A) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "`Permutation.__new__` internally uses `_af_new`" =>
  //   every fresh-allocation fast path in `__new__` must preserve `cls`.
  claim
    <k> constructorFast(C:Class, CASE:CtorCase, A:List) => .K </k>
    <result> noObj => obj(C, A) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the array/cyclic-form fallthrough path uses
  //   `Basic.__new__(cls, aform)`, already preserving the requested class.
  claim
    <k> constructorArray(C:Class, A:List) => .K </k>
    <result> noObj => obj(C, A) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: constructing through a subclass must not return a base
  //   `Permutation` merely because the input is a base `Permutation`.
  claim
    <k> constructExisting(Sub, obj(Perm, A:List)) => .K </k>
    <result> noObj => obj(Sub, A) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: existing `Permutation(existing_perm)` identity behavior is
  //   preserved when the input object is already an instance of the requested
  //   class.
  claim
    <k> constructExisting(Perm, obj(Sub, A:List)) => .K </k>
    <result> noObj => obj(Sub, A) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "subclassed properly" plus Python method dispatch =>
  //   inherited operations that allocate fresh permutations preserve receiver
  //   class.
  claim
    <k> operationFresh(obj(C:Class, OLD:List), A:List) => .K </k>
    <result> noObj => obj(C, A) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: classmethods should use the class they are called on.
  claim
    <k> classmethodFresh(C:Class, A:List) => .K </k>
    <result> noObj => obj(C, A) </result>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: module-level aliases bind `Permutation._af_new`; preserving
  //   those aliases as base-bound keeps existing combinatorics internals
  //   compatible.
  claim
    <k> moduleAliasAfNew(A:List) => .K </k>
    <result> noObj => obj(Perm, A) </result>
    [all-path]
endmodule

