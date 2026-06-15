requires "mini-python-attr.k"

module SKYCOORD-ATTRIBUTE-ACCESS-SPEC
  imports MINI-PYTHON-ATTR

  // SPEC-PROVENANCE:
  // - E1/E2/E3: custom SkyCoord property prop tries self.random_attr;
  //   final AttributeError should name random_attr, not prop.
  // - F2: V1 replayed the descriptor; V2 must not replay it.
  claim <k> access(attr("prop")) => done(raised(attrError(attr("random_attr")))) </k>
        <firstProvider> attr("prop") |-> customProperty </firstProvider>
        <propertyError> attr("prop") |-> attrError(attr("random_attr")) </propertyError>
        <marker> noMarker </marker>

  // SPEC-PROVENANCE:
  // - E4/PO3: non-custom-property missing attributes use the unchanged
  //   SkyCoord fallback path.
  claim <k> access(attr("ordinary_missing")) => done(skyFallback(attr("ordinary_missing"))) </k>
        <firstProvider> attr("ordinary_missing") |-> noProvider </firstProvider>
        <propertyError> .Map </propertyError>
        <marker> noMarker </marker>

  // SPEC-PROVENANCE:
  // - E5/PO4: a provider inside SkyCoord's own hierarchy is not intercepted as
  //   a custom subclass property.
  claim <k> access(attr("frame")) => done(skyFallback(attr("frame"))) </k>
        <firstProvider> attr("frame") |-> skycoordProvider </firstProvider>
        <propertyError> .Map </propertyError>
        <marker> noMarker </marker>
endmodule

