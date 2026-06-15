requires "domains.md"

module MINI-PYTHON-ATTR-SYNTAX
  imports BOOL
  imports STRING

  syntax Attr ::= attr(String)
  syntax Err ::= attrError(Attr)
  syntax Provider ::= noProvider | skycoordProvider | customProperty | customOther
  syntax Marker ::= noMarker | marker(Attr, Err)
  syntax Outcome ::= raised(Err) | skyFallback(Attr)
  syntax KItem ::= access(Attr)
                 | pyGetattribute(Attr)
                 | propertyGet(Attr)
                 | pyGetattr(Attr)
                 | raise(Err)
                 | done(Outcome)
endmodule

module MINI-PYTHON-ATTR
  imports MINI-PYTHON-ATTR-SYNTAX
  imports MAP

  configuration
    <k> $PGM:K </k>
    <firstProvider> .Map </firstProvider>
    <propertyError> .Map </propertyError>
    <marker> noMarker </marker>

  // Normal attribute access enters __getattribute__.
  rule <k> access(A) => pyGetattribute(A) ... </k>

  // The audited custom-property path: the first MRO provider is a custom
  // property, and descriptor evaluation raises an AttributeError.
  rule <k> pyGetattribute(A) => propertyGet(A) ... </k>
       <firstProvider> ... A |-> customProperty ... </firstProvider>

  rule <k> propertyGet(A) => raise(E) ... </k>
       <propertyError> ... A |-> E ... </propertyError>

  // V2 captures the original property AttributeError before Python calls
  // __getattr__ for the property name.
  rule <k> raise(E) => pyGetattr(A) ... </k>
       <firstProvider> ... A |-> customProperty ... </firstProvider>
       <marker> noMarker => marker(A, E) </marker>

  // __getattr__ re-raises the saved exception without replaying propertyGet.
  rule <k> pyGetattr(A) => done(raised(E)) ... </k>
       <marker> marker(A, E) => noMarker </marker>

  // Non-custom-property cases fall through to the unchanged SkyCoord fallback.
  rule <k> pyGetattribute(A) => pyGetattr(A) ... </k>
       <firstProvider> ... A |-> noProvider ... </firstProvider>

  rule <k> pyGetattribute(A) => pyGetattr(A) ... </k>
       <firstProvider> ... A |-> skycoordProvider ... </firstProvider>

  rule <k> pyGetattribute(A) => pyGetattr(A) ... </k>
       <firstProvider> ... A |-> customOther ... </firstProvider>

  rule <k> pyGetattr(A) => done(skyFallback(A)) ... </k>
       <marker> noMarker </marker>
endmodule

