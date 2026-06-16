requires "mini-copy-routing.k"

module LASSO-LARS-IC-COPY-X-SPEC
  imports MINI-COPY-ROUTING

  // SPEC-PROVENANCE:
  // - from_prompt: "fit takes a default value of None" =>
  //   an omitted method argument is represented by None after Python default
  //   binding.
  // - from_prompt: "only overwrites the existing value if the user has
  //   explicitly passed it as an argument to fit" =>
  //   None uses the constructor value self.copy_X.
  // - from_code: least_angle.py lines 1504-1515 resolve the local copy_X
  //   value before passing it to _preprocess_data and lars_path.
  claim
    <k> fitRoute(SelfCopy:Bool, None) => (SelfCopy, SelfCopy) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "there are two values (potentially contradicting each
  //   other) for copy_X and each one is used once" =>
  //   no fit call may route two different copy_X values internally.
  // - from_prompt: explicit fit copy_X is retained for backward compatibility.
  // - from_code: least_angle.py lines 1507-1515 pass the same local copy_X to
  //   both copy-sensitive downstream operations.
  claim
    <k> fitRoute(SelfCopy:Bool, FitCopy:Bool) => (FitCopy, FitCopy) </k>
    [all-path]
endmodule
