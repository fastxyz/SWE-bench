// Constructed, not machine-checked.

requires "mini-python-signature.k"

module MANAGER-SIGNATURE-SPEC
  imports MINI-PYTHON-SIGNATURE

  // SPEC-PROVENANCE:
  // - from_prompt: "inspect.signature returns incorrect signature information"
  //   => copied manager methods must expose queryset method signatures.
  // - from_prompt: "complete metadata is not copied" and "use functools.wraps"
  //   => createProxy must retain wrapper metadata pointing to the original.
  // - from_code: _get_queryset_methods() only copies eligible queryset methods;
  //   eligibility is a precondition of this claim, not redefined here.
  claim <k>
          inspectSignature(
            bound(
              "manager",
              createProxy(
                NAME,
                method(
                  METHODNAME,
                  ListItem(param("self")) PARAMS,
                  noWrapped
                )
              )
            )
          )
        => PARAMS
        ... </k>
    [all-path]

endmodule
