module MINI-DJANGO-FORMATS-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  syntax FType ::= strType(String)
                 | promiseType(String)
                 | otherType(String)

  syntax Val ::= cacheValue(String)
               | moduleValue(String)
               | settingsValue(String)
               | rawFormat(String)
               | typeError(String)

  syntax Stmt ::= getFormat(FType, Bool, Bool, Bool, Bool)
                | normalize(FType)
                | continueWith(Bool, Bool, Bool, Bool)
                | resolve(String, Bool, Bool, Bool, Bool)
                | return(Val)

  syntax KResult ::= FType | Val
endmodule

module MINI-DJANGO-FORMATS
  imports MINI-DJANGO-FORMATS-SYNTAX
  imports BOOL
  imports STRING

  configuration <k> $PGM:Stmt </k>

  // Abstract arguments to getFormat(FT, USE_L10N, CACHE_HIT, MODULE_HAS,
  // IN_FORMAT_SETTINGS). The four booleans summarize the environment branches
  // relevant to the regression without modeling Django settings or imports.
  rule <k> getFormat(FT, USE, CACHE, MODULE, INSETTINGS)
        => normalize(FT) ~> continueWith(USE, CACHE, MODULE, INSETTINGS)
           ... </k>

  // V2/V1 fix under audit: a Django Promise that represents a string is forced
  // to the concrete string before cache, module getattr, settings getattr, or
  // arbitrary-format fallback.
  rule <k> normalize(promiseType(S)) => strType(S) ... </k>
  rule <k> normalize(strType(S)) => strType(S) ... </k>

  // Non-Promise, non-string values are outside the specified lazy-string
  // domain. This rule is present only to show the model does not prove broad
  // coercion of arbitrary objects.
  rule <k> normalize(otherType(S)) => otherType(S) ... </k>

  rule <k> strType(S) ~> continueWith(USE, CACHE, MODULE, INSETTINGS)
        => resolve(S, USE, CACHE, MODULE, INSETTINGS)
           ... </k>

  // Pre-fix failure shape for out-of-domain non-string values on the localized
  // module lookup path. The Promise path cannot reach this rule because it is
  // normalized to strType first.
  rule <k> otherType(S) ~> continueWith(true, false, MODULE, INSETTINGS)
        => return(typeError("getattr(): attribute name must be string"))
           ... </k>

  // Cache hit returns the cached value for the normalized key.
  rule <k> resolve(S, USE, true, MODULE, INSETTINGS)
        => return(cacheValue(S))
           ... </k>

  // Localized format-module lookup path.
  rule <k> resolve(S, true, false, true, INSETTINGS)
        => return(moduleValue(S))
           ... </k>

  // Settings fallback for registered format setting names.
  rule <k> resolve(S, true, false, false, true)
        => return(settingsValue(S))
           ... </k>
  rule <k> resolve(S, false, false, MODULE, true)
        => return(settingsValue(S))
           ... </k>

  // Arbitrary custom date format fallback, e.g. "Y-m-d".
  rule <k> resolve(S, true, false, false, false)
        => return(rawFormat(S))
           ... </k>
  rule <k> resolve(S, false, false, MODULE, false)
        => return(rawFormat(S))
           ... </k>
endmodule
