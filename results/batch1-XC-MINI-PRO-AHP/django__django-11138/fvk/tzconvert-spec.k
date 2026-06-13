// tzconvert-spec.k — reachability claims for the V1 fix
// =====================================================
// CONSTRUCTED, NOT MACHINE-CHECKED.
//
// Each claim is a function contract phi_pre => phi_post (no loops => no
// circularity claims). The shared specification value is
//
//     SPEC(F, C, T)  ==  wallOf(instant(F, C), T)
//
// "take the stored wall-clock F, read it as an instant in the connection zone
//  C, then express that instant as a wall-clock in the active Django zone T."
//
// This is the documented intent (timezones.txt): when USE_TZ and the backend
// does not support time zones, datetimes are stored in the per-database
// TIME_ZONE (C); a lookup converts the field to the current zone (T) before
// truncating/extracting.

requires "tzconvert.k"

module TZCONVERT-SPEC-SYNTAX
  imports TZCONVERT-SYNTAX
endmodule

module VERIFICATION
  imports TZCONVERT-SPEC-SYNTAX
  imports TZCONVERT
  imports K-EQUAL
endmodule

module TZCONVERT-SPEC
  imports VERIFICATION

  // (MYSQL) / (ORACLE) — SQL backends, USE_TZ = true.
  // The generated transform denotes exactly SPEC(F, C, T), for ALL F, C, T.
  // Proof: case split on C == T (the `gen` branches); the equal branch closes
  // by the round-trip axiom (RT). No side condition needed — fully general.
  claim <k> denote(gen(true, C:Zone, T:Zone), F:Int, C) => wallOf(instant(F, C), T) </k>
    [all-path]

  // (SQL-OFF) — SQL backends, USE_TZ = false: no conversion, raw field.
  claim <k> denote(gen(false, C:Zone, _T:Zone), F:Int, C) => F </k>
    [all-path]

  // (SQLITE) — SQLite in-process parse, USE_TZ = true.
  // Provably equals SPEC(F, C, T) ONLY under the side condition
  //     C == T  OR  C == "UTC"
  // (equal-zone identity, or UTC where `.replace` is exact). For a named
  // non-UTC C with C != T the claim does NOT hold (off by pytz's LMT delta):
  // that is FINDING F1, not a provable contract — left explicit, not papered over.
  claim <k> parse(F:Int, C:Zone, T:Zone) => wallOf(instant(F, C), T) </k>
    requires (C ==String T orBool C ==String "UTC") andBool C =/=String ""
    [all-path]

  // (SQLITE-OFF) — SQLite, USE_TZ = false (C = "" sentinel): naive passthrough.
  claim <k> parse(F:Int, "", _T:Zone) => F </k>
    [all-path]
endmodule
