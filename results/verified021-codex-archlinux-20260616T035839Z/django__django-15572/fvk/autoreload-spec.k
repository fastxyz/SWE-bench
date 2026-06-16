// Constructed claims for the directory filtering slice of
// django.template.autoreload. This file was not parsed or machine-checked.

requires "mini-autoreload.k"

module AUTORELOAD-SPEC
  imports MINI-AUTORELOAD

  // SPEC-PROVENANCE:
  // - E1/E3: empty string must not become the current working directory.
  claim collectBackend(ListItem(EmptyString()) DS, CWD)
    => collectBackend(DS, CWD)
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6: loader get_dirs() is another contributor and must filter the
  //   same empty string before normalization.
  claim collectLoader(ListItem(EmptyString()) DS, CWD)
    => collectLoader(DS, CWD)
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: non-empty relative string and Path values keep the existing
  //   normalization behavior.
  claim collectBackend(ListItem(D) DS, CWD)
    => SetItem(Norm(CWD, D)) collectBackend(DS, CWD)
    requires notBool isEmptyString(D)
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: if both contributors contain only empty strings, the collected set is
  //   empty; therefore cwd is not watched because of the invalid value.
  claim collectAll(ListItem(EmptyString()), ListItem(EmptyString()), Cwd())
    => .Set
    [all-path]
endmodule

