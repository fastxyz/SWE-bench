requires "fvk/mini-django-save.k"

module SAVE-TABLE-SPEC
  imports MINI-DJANGO-SAVE

  // SPEC-PROVENANCE:
  // - from_prompt: "loaddata ... fixture contains explicit pk values and the objects already exist"
  //   => raw saves with pk/default/existing row must try UPDATE and avoid INSERT.
  claim <k> saveTable(true, false, true, true, true, true)
        => saved(true, update .Queries)
       </k>
       [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: same fixture path, but when the row is absent, historical save semantics
  //   fall back from UPDATE to INSERT.
  claim <k> saveTable(true, false, true, true, true, false)
        => saved(false, update insert .Queries)
       </k>
       [all-path]

  // SPEC-PROVENANCE:
  // - from_public_hint: "it does reduce the number of queries significantly when using primary key defaults"
  //   => ordinary non-raw creation with a generated pk default keeps the insert-only optimization.
  claim <k> saveTable(false, false, true, true, true, false)
        => saved(false, insert .Queries)
       </k>
       [all-path]
endmodule
