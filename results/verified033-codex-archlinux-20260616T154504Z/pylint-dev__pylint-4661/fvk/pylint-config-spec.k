requires "mini-python-config.k"

module PYLINT-CONFIG-SPEC
  imports MINI-PYLINT-CONFIG

  // SPEC-PROVENANCE:
  // - E3: PYLINTHOME is a directory "of your choice" => exact override.
  claim <k> resolveHome(true, PYLINTHOME:String, HOME:String, XDGVALID:Bool, XDG:String)
        => PYLINTHOME ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E5: normal default should be XDG cache, not ~/.pylint.d.
  claim <k> resolveHome(false, PYLINTHOME:String, HOME:String, true, XDG:String)
        => join(XDG, "pylint") ... </k>
    requires HOME =/=String "~"
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E5: missing or invalid XDG_CACHE_HOME falls back to ~/.cache/pylint.
  claim <k> resolveHome(false, PYLINTHOME:String, HOME:String, false, XDG:String)
        => join(join(HOME, ".cache"), "pylint") ... </k>
    requires HOME =/=String "~"
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: .pylint.d current-directory fallback remains when home is unavailable.
  claim <k> resolveHome(false, PYLINTHOME:String, "~", XDGVALID:Bool, XDG:String)
        => ".pylint.d" ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: nested XDG paths require recursive directory creation.
  claim <k> mkdirsIfMissing(PATH:String, true) => PATH ... </k>
        <created> false => true </created>
        <createdPath> "" => PATH </createdPath>
    [all-path]

  // SPEC-PROVENANCE:
  // - Frame condition: existing directory needs no create effect.
  claim <k> mkdirsIfMissing(PATH:String, false) => PATH ... </k>
        <created> false => false </created>
        <createdPath> "" => "" </createdPath>
    [all-path]
endmodule

