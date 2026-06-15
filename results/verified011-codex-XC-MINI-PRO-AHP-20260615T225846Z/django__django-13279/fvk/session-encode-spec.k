requires "mini-session-format.k"

module SESSION-ENCODE-SPEC
  imports MINI-SESSION-FORMAT

  // SPEC-PROVENANCE:
  // - from_prompt: "We could use the legacy encode() when DEFAULT_HASHING_ALGORITHM == 'sha1'."
  //   => transition-mode SessionBase.encode() must emit the legacy session format.
  // - from_code: _legacy_decode() expects base64(hash + ":" + serialized), represented
  //   here by legacyEncoded(C, legacyHash(C, serialized(D)), serialized(D)).
  claim <k> encode(C:StoreClass, D:Data, SHA1)
        => legacyEncoded(C, legacyHash(C, serialized(D)), serialized(D))
        </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "Session data cannot be decoded during the transition to Django 3.1."
  //   => a SHA1 transition-mode write must be accepted by a pre-3.1 legacy decoder.
  claim <k> legacyDecode(C:StoreClass, encode(C, D:Data, SHA1))
        => D
        </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: SessionBase.decode() falls back to _legacy_decode().
  //   => Django 3.1 continues accepting legacy stored session data.
  claim <k> decode(C:StoreClass, legacyEncoded(C, legacyHash(C, serialized(D)), serialized(D)))
        => D
        </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: DEFAULT_HASHING_ALGORITHM default is 'sha256'.
  // - frame_condition: default mode must preserve the Django 3.1 signing-based format.
  claim <k> encode(C:StoreClass, D:Data, SHA256)
        => signedEncoded(C, D)
        </k>
        [all-path]

  // SPEC-PROVENANCE:
  // - from_code: signing.loads() handles the signed payload produced by signing.dumps().
  //   => current-format round trip remains available.
  claim <k> decode(C:StoreClass, signedEncoded(C, D:Data))
        => D
        </k>
        [all-path]
endmodule

