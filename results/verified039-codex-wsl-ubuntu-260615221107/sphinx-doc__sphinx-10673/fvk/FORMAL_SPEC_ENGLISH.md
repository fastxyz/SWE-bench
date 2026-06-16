# Formal Spec English

Status: constructed, not machine-checked.

The K claims in `toctree-generated-pages-spec.k` say the following:

1. `PARSE-GENINDEX`, `PARSE-MODINDEX`, and `PARSE-SEARCH`: for each named
   generated ref, parsing appends exactly one toctree entry, appends no
   includefile, and leaves the warning list unchanged.
2. `RESOLVE-GENINDEX`, `RESOLVE-MODINDEX`, and `RESOLVE-SEARCH`: for each named
   generated ref, resolving appends exactly one link whose target and title come
   from the standard-domain label map.
3. `RESOLVE-GENINDEX-EXPLICIT`: an explicit toctree title overrides the
   standard-domain label title.
4. `UNKNOWN-STILL-WARNS`: a missing ref that is not one of the generated refs
   still appends a nonexisting-document warning.
5. `SOURCE-DOC-WINS`: if the normal source-document lookup succeeds, parsing
   records a source entry and includefile rather than taking the generated-label
   path.
6. `SECTION-SKIP-GENERATED` and `FIGURE-SKIP-GENERATED`: numbering traversal
   leaves numbering state and warning state unchanged for generated refs.
