requires "mini-django-formats.k"

module GET-FORMAT-SPEC
  imports MINI-DJANGO-FORMATS
  imports BOOL
  imports STRING

  // SPEC-PROVENANCE:
  // - from_prompt: "get_format should allow lazy parameter" => Promise-backed
  //   lazy strings are in-domain format_type inputs.
  // - from_prompt: "like in some_date|date:_('Y-m-d')" => arbitrary lazy
  //   custom format strings must fall back to the concrete string.
  // - from_prompt: "TypeError: getattr(): attribute name must be string" =>
  //   Promise must not reach string-only getattr paths.
  // - from_code: get_format branches over cache, localized module lookup,
  //   registered settings fallback, and arbitrary-format fallback.
  claim
    <k> getFormat(promiseType(S:String), true, false, false, false)
      => return(rawFormat(S)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "possibly others are affected too" and function name
  //   "get_format" => fix belongs in the shared helper, not only the date
  //   template filter.
  // - from_code: localized format module lookup uses getattr(module,
  //   format_type, None); the normalized string may find a module value.
  claim
    <k> getFormat(promiseType(S:String), true, false, true, INSETTINGS:Bool)
      => return(moduleValue(S)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: if no localized module value exists and the normalized name is
  //   a registered format setting, get_format falls back to settings.
  // - from_prompt: lazy input should be accepted on the same paths as a string.
  claim
    <k> getFormat(promiseType(S:String), true, false, false, true)
      => return(settingsValue(S)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: with localization disabled, get_format skips module lookup
  //   and uses settings for registered format setting names.
  // - frame condition: Promise normalization must not depend on localization.
  claim
    <k> getFormat(promiseType(S:String), false, false, MODULE:Bool, true)
      => return(settingsValue(S)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the concrete example "_('Y-m-d')" is an arbitrary format
  //   string, not a registered setting name.
  // - frame condition: lazy arbitrary strings are returned as their evaluated
  //   string, matching existing get_format behavior for concrete strings.
  claim
    <k> getFormat(promiseType(S:String), false, false, MODULE:Bool, false)
      => return(rawFormat(S)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: cache key is computed after Promise normalization in V1.
  // - frame condition: cache hits use the same normalized key as concrete
  //   string callers.
  claim
    <k> getFormat(promiseType(S:String), USE:Bool, true, MODULE:Bool, INSETTINGS:Bool)
      => return(cacheValue(S)) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_baseline_notes: coercing every non-string input was rejected.
  // - frame condition: this proof does not assert arbitrary object support.
  claim
    <k> getFormat(otherType(S:String), true, false, MODULE:Bool, INSETTINGS:Bool)
      => return(typeError("getattr(): attribute name must be string")) ... </k>
    [all-path]
endmodule
