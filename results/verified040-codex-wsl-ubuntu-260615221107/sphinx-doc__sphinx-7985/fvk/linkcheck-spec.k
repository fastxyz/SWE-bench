requires "mini-linkcheck.k"

module LINKCHECK-SPEC
  imports MINI-LINKCHECK

  // SPEC-PROVENANCE:
  // - IE1/IE2: missing relative local target must be broken.
  claim <k> checkLocal("doesntexist", DOC:String)
            => ("broken", "local file not found") ... </k>
        <docUri> DOCURI:Map </docUri>
        <files> FILES:Set </files>
    requires notBool localDocExists("doesntexist", DOCURI)
     andBool notBool localFileExists("doesntexist", FILES)

  // SPEC-PROVENANCE:
  // - IE3: known Sphinx document URI is local.
  claim <k> checkLocal(URI:String, DOC:String) => ("local", "") ... </k>
        <docUri> DOCURI:Map </docUri>
    requires localDocExists(resolvedTarget(URI, DOC), DOCURI)

  // SPEC-PROVENANCE:
  // - IE3: visible source-tree file is local.
  claim <k> checkLocal(URI:String, DOC:String) => ("local", "") ... </k>
        <docUri> DOCURI:Map </docUri>
        <files> FILES:Set </files>
    requires notBool localDocExists(resolvedTarget(URI, DOC), DOCURI)
     andBool localFileExists(resolvedTarget(URI, DOC), FILES)

  // SPEC-PROVENANCE:
  // - IE4: absolute/scheme URI forms are uncheckable and stay local.
  claim <k> checkLocal(URI:String, DOC:String) => ("local", "") ... </k>
    requires isAbsoluteOrScheme(URI)

  // SPEC-PROVENANCE:
  // - IE5: opt-out preserves local status.
  claim <k> checkLocal(URI:String, DOC:String) => ("local", "") ... </k>
        <localLinks> false </localLinks>

  // SPEC-PROVENANCE:
  // - IE6: broken result changes builder status.
  claim <k> processResult(("broken", INFO:String), DOC:String) => .K ... </k>
        <hasBroken> false => true </hasBroken>
        <statuscode> 0 => 1 </statuscode>
endmodule
