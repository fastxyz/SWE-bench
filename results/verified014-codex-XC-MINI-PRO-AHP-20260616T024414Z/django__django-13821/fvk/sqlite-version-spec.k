requires "mini-python.k"

module SQLITE-VERSION-SPEC
  imports MINI-PYTHON

  // SPEC-PROVENANCE:
  // - from_prompt: "Drop support for SQLite < 3.9.0" => reject every version
  //   tuple lexicographically below (3, 9, 0).
  // - from_code: check_sqlite_version() raises ImproperlyConfigured for an
  //   unsupported version and includes Database.sqlite_version in the message.
  claim [reject-sqlite-below-390]:
    <k> checkSqliteVersion(version(M, N, P), S)
     => raised("SQLite 3.9.0 or later is required (found " +String S +String ").")
    </k>
    requires M >=Int 0
     andBool N >=Int 0
     andBool P >=Int 0
     andBool below390(version(M, N, P))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "SQLite < 3.9.0" is unsupported, so (3, 9, 0) itself and
  //   later versions remain in domain.
  // - from_prompt: "SQLite 3.11.0 (which will still by supported by Django)"
  //   => newer versions must not be rejected by the support-floor guard.
  claim [accept-sqlite-390-or-newer]:
    <k> checkSqliteVersion(version(M, N, P), S) => ok </k>
    requires M >=Int 0
     andBool N >=Int 0
     andBool P >=Int 0
     andBool notBool below390(version(M, N, P))
    [all-path]
endmodule
