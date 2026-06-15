requires "mini-python-fits.k"

module FITS-FROMSTRING-SPEC
  imports MINI-PYTHON-FITS

  // SPEC-PROVENANCE:
  // - E1/E2/E5: Header.fromstring must accept Python 3 bytes.
  // - E4/E7/E8: bytes are decoded through the same ASCII boundary used by
  //   binary-file header reading.
  // - This claim proves bytes header data plus text separator reaches the text
  //   parser instead of the bytes TypeError path.
  claim
    <k> Header.fromstring(Bytes(DATA), Str(SEP)) => Header(DATA) </k>
    requires ascii(DATA)
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E5: Header.fromstring accepts bytes header data.
  // - IS-4: a bytes separator should be normalized too, preventing mixed
  //   bytes/text operations.
  claim
    <k> Header.fromstring(Bytes(DATA), Bytes(SEP)) => Header(DATA) </k>
    requires ascii(DATA) andBool ascii(SEP)
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: Python 3 str input already works and must remain preserved.
  // - E9: public callsites pass text strings.
  claim
    <k> Header.fromstring(Str(DATA), Str(SEP)) => Header(DATA) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: Card.fromstring needs the same bytes treatment.
  // - E8: use the existing ASCII decoding policy.
  claim
    <k> Card.fromstring(Bytes(IMAGE)) => Card(pad80(IMAGE)) </k>
    requires ascii(IMAGE)
    [all-path]

  // SPEC-PROVENANCE:
  // - E9: existing text card callsites must continue to work unchanged.
  claim
    <k> Card.fromstring(Str(IMAGE)) => Card(pad80(IMAGE)) </k>
    [all-path]
endmodule

