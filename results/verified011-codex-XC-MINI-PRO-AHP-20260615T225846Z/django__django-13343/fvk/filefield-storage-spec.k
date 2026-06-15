requires "mini-python-filefield.k"

module FILEFIELD-STORAGE-SPEC
  imports MINI-PYTHON-FILEFIELD

  // SPEC-PROVENANCE:
  // - from_prompt: "return a reference to the original callable during deconstruction"
  //   => callable storage deconstructs to that callable, not to its result.
  // - from_prompt: "should not actually evaluate the callable when it is being deconstructed"
  //   => deconstruct preserves the construction-time call count.
  claim <k> init(callable(C, storage(S)), U)
        => result(kwargs(("upload_to" |-> U) ["storage" <- callable(C, storage(S))])) </k>
       <calls> 0 => 1 </calls>

  // SPEC-PROVENANCE:
  // - from_prompt: dynamic storage selection must not be frozen.
  //   => even a callable that returns defaultStorage is serialized as the callable.
  claim <k> init(callable(C, defaultStorage), U)
        => result(kwargs(("upload_to" |-> U) ["storage" <- callable(C, defaultStorage)])) </k>
       <calls> 0 => 1 </calls>

  // SPEC-PROVENANCE:
  // - from_implementation_frame: explicit non-default storage was serialized before the fix.
  //   => preserve non-callable storage kwargs.
  claim <k> init(storageArg(S), U)
        => result(kwargs(("upload_to" |-> U) ["storage" <- storageArg(S)])) </k>
       <calls> 0 </calls>

  // SPEC-PROVENANCE:
  // - from_implementation_frame: default storage was omitted before the fix.
  //   => preserve default omission when no callable was supplied.
  claim <k> init(defaultStorageArg, U)
        => result(kwargs(("upload_to" |-> U))) </k>
       <calls> 0 </calls>

  // SPEC-PROVENANCE:
  // - from_implementation_frame: callable result must be a Storage.
  //   => preserve the existing TypeError path for invalid callable results.
  claim <k> init(callable(C, invalid), U)
        => result(typeError) </k>
       <calls> 0 => 1 </calls>
endmodule
