requires "mini-urlize.k"

module URLIZE-TRIM-SPEC
  imports MINI-URLIZE

  // SPEC-PROVENANCE:
  // - I-001/I-002: reported input must keep "&lt" inside the link and move only
  //   the final "!" outside.
  // - I-003/I-004: trailing punctuation is outside the link, but entities are
  //   not broken by trimming their semicolon.
  // - I-005/I-006: display source is preserved; literal punctuation runs move.

  claim <k>
      trim(
        span("google.com/?q=1", "google.com/?q=1")
        span("&lt", "<")
        span("!", "!")
        .Spans
      )
    => result(
        span("google.com/?q=1", "google.com/?q=1")
        span("&lt", "<")
        .Spans,
        span("!", "!")
        .Spans
      )
    </k>
    [label(REPORTED-LT-BANG)]

  claim <k>
      trim(
        span("google.com/?q=1", "google.com/?q=1")
        span("&lt;", "<")
        span("!", "!")
        .Spans
      )
    => result(
        span("google.com/?q=1", "google.com/?q=1")
        span("&lt;", "<")
        .Spans,
        span("!", "!")
        .Spans
      )
    </k>
    [label(VALID-LT-BANG)]

  claim <k>
      trim(
        span("google.com/", "google.com/")
        span("&#33;", "!")
        .Spans
      )
    => result(
        span("google.com/", "google.com/")
        .Spans,
        span("&#33;", "!")
        .Spans
      )
    </k>
    [label(ENCODED-BANG)]

  claim <k>
      trim(
        span("google.com/", "google.com/")
        span("&semi;", ";")
        span("!", "!")
        .Spans
      )
    => result(
        span("google.com/", "google.com/")
        .Spans,
        span("&semi;", ";")
        span("!", "!")
        .Spans
      )
    </k>
    [label(ENCODED-SEMI-LITERAL-BANG)]

  claim <k>
      trim(
        span("http://testing.com/example", "http://testing.com/example")
        span("!!", "!!")
        .Spans
      )
    => result(
        span("http://testing.com/example", "http://testing.com/example")
        .Spans,
        span("!!", "!!")
        .Spans
      )
    </k>
    [label(LITERAL-PUNCT-RUN)]
endmodule
