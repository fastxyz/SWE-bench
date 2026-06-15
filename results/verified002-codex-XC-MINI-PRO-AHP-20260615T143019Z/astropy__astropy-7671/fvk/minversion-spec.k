requires "mini-python.k"

module MINVERSION-SPEC
  imports MINI-PYTHON

  // SPEC-PROVENANCE:
  // - from_prompt: "parse_version('1.14.3') >= parse_version('1.14dev') True"
  //   => the reported minversion comparison should return True.
  // - from_prompt: LooseVersion raises TypeError on the same raw strings
  //   => suffix normalization must happen before LooseVersion comparison.
  claim
    <k>
      minversion(
        moduleWithVersion(numeric(rcons(1, rcons(14, rcons(3, rnil()))), "")),
        numeric(rcons(1, rcons(14, rnil())), "dev"),
        true
      )
      => ok(true)
    </k>

  // SPEC-PROVENANCE:
  // - from_docstring: inclusive=True means the specified version meets the
  //   requirement inclusively, i.e. >=.
  // - from_hint: restore regex guard around LooseVersion.
  claim
    <k>
      minversion(moduleWithVersion(numeric(HAVE, HSuffix)),
                 numeric(REQUIRED, RSuffix),
                 true)
      => ok(looseGe(HAVE, REQUIRED))
    </k>

  // SPEC-PROVENANCE:
  // - from_docstring: inclusive=False means strictly greater than the specified
  //   minimum version.
  // - from_hint: restore regex guard around LooseVersion.
  claim
    <k>
      minversion(moduleWithVersion(numeric(HAVE, HSuffix)),
                 numeric(REQUIRED, RSuffix),
                 false)
      => ok(looseGt(HAVE, REQUIRED))
    </k>

  // SPEC-PROVENANCE:
  // - from_docstring/source: if importing a module by name fails, minversion
  //   returns False.
  claim
    <k>
      minversion(missingImport(), REQUIRED, INCLUSIVE)
      => ok(false)
    </k>

  // SPEC-PROVENANCE:
  // - from_docstring/source: invalid module arguments raise ValueError before
  //   version lookup or comparison.
  claim
    <k>
      minversion(invalidModule(), REQUIRED, INCLUSIVE)
      => valueError()
    </k>
endmodule
