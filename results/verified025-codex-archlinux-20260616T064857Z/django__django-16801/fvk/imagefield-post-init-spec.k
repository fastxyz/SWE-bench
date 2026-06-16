requires "mini-django-imagefield.k"

module IMAGEFIELD-POST-INIT-SPEC
  imports MINI-DJANGO-IMAGEFIELD

  // SPEC-PROVENANCE:
  // - E1/E2/E3: No width_field and no height_field means no post_init receiver.
  claim <k> contribute(false, false, false)
        => connected(false) </k> [all-path]

  // SPEC-PROVENANCE:
  // - E4/E8: A concrete width-bearing ImageField still registers the receiver.
  claim <k> contribute(false, true, false)
        => connected(true) </k> [all-path]

  // SPEC-PROVENANCE:
  // - E4/E8: A concrete height-bearing ImageField still registers the receiver.
  claim <k> contribute(false, false, true)
        => connected(true) </k> [all-path]

  // SPEC-PROVENANCE:
  // - E4: A concrete ImageField with both dimensions still registers.
  claim <k> contribute(false, true, true)
        => connected(true) </k> [all-path]

  // SPEC-PROVENANCE:
  // - E5: Abstract models do not directly register post_init receivers.
  claim <k> contribute(true, W:Bool, H:Bool)
        => connected(false) </k> [all-path]

  // SPEC-PROVENANCE:
  // - E2/E3: No-dimension update_dimension_fields() is a state no-op.
  claim <k> updateDims(false, false, Deferred:Bool)
        => dimensionsChanged(false) </k> [all-path]

  // SPEC-PROVENANCE:
  // - E6: Assignment with a previous file still forces dimension update.
  claim <k> assignImage(true)
        => forceUpdateCalled(true) </k> [all-path]
endmodule
