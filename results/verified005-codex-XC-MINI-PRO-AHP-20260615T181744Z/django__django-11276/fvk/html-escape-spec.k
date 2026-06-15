// K-style claims for django.utils.html.escape V1.
// Constructed, not machine-checked.

requires "mini-python.k"

module HTML-ESCAPE-SPEC
  imports MINI-DJANGO-HTML

  // SPEC-PROVENANCE:
  // - E1/E2: public issue requires replacing Django's duplicate table with
  //   Python stdlib html.escape().
  // - E6/E8: docstrings require escaping text for HTML and returning safe text.
  // - D1/D3: assumes str(TEXT) and stdlib html.escape(TEXT, quote=True)
  //   terminate.
  claim <k> escape(Obj(S:String)) => SafeString(HtmlEscape(S)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: escape() must always escape, even if input is already marked safe.
  claim <k> escape(SafeString(S:String)) => SafeString(HtmlEscape(S)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: stdlib html.escape() intentionally emits the apostrophe as &#x27;.
  claim <k> escape(Obj("'")) => SafeString("&#x27;") </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6 and stdlib html.escape(quote=True): representative core characters.
  claim <k> escape(Obj("&")) => SafeString("&amp;") </k> [all-path]
  claim <k> escape(Obj("<")) => SafeString("&lt;") </k> [all-path]
  claim <k> escape(Obj(">")) => SafeString("&gt;") </k> [all-path]
  claim <k> escape(Obj("\"")) => SafeString("&quot;") </k> [all-path]

  // SPEC-PROVENANCE:
  // - E10: escaped URL input is unescaped before smart_urlquote().
  // - I7: after stdlib escaping, &#x27; must be accepted alongside &#39;.
  claim <k> url_unescape("http://example.test/?q=&#x27;") =>
            "http://example.test/?q='" </k>
    [all-path]

  claim <k> url_unescape("http://example.test/?q=&#39;") =>
            "http://example.test/?q='" </k>
    [all-path]

endmodule
