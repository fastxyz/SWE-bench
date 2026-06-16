requires "mini-python-filefield.k"

module FILEFIELD-DECONSTRUCT-SPEC
  imports MINI-PYTHON-FILEFIELD

  // SPEC-PROVENANCE:
  // - from_docs: FileField.storage is "A storage object, or a callable which returns a storage object."
  // - from_docs: deconstruct() returns arguments used to recreate a field.
  // - obligation: implicit default storage is omitted as a default.
  // Claim DEFAULT-IMPLICIT.
  claim
    <k> initThenDeconstruct(noStorageArg) => omitStorage </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: default values may be omitted when not necessary to reconstruct state.
  // - obligation: direct default storage is omitted.
  // Claim DIRECT-DEFAULT.
  claim
    <k> initThenDeconstruct(direct(defaultStorage)) => omitStorage </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: explicit storage object is a public FileField.storage input.
  // - obligation: direct non-default storage is serialized.
  // Claim DIRECT-OTHER.
  claim
    <k> initThenDeconstruct(direct(otherStorage)) => includeStorage(serializedStorage(otherStorage)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: callable storage returning default_storage must be included as a reference to the callable.
  // - from_hint: use getattr(self, "_storage_callable", self.storage) in both comparison and assignment.
  // - obligation: callable default result serializes the original callable.
  // Claim CALLABLE-DEFAULT.
  claim
    <k> initThenDeconstruct(callable(getDefaultStorage, defaultStorage)) => includeStorage(serializedCallable(getDefaultStorage)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: deconstructing callable storage gives the original callable, not the evaluated value.
  // - obligation: callable non-default result still serializes the original callable.
  // Claim CALLABLE-OTHER.
  claim
    <k> initThenDeconstruct(callable(getOtherStorage, otherStorage)) => includeStorage(serializedCallable(getOtherStorage)) </k>
    [all-path]
endmodule
