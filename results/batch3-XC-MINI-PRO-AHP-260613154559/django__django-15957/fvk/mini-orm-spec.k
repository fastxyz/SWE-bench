// mini-orm-spec.k — reachability claims for the bug-relevant fragment of the
// django__django-15957 fix.  Constructed, NOT machine-checked.
//
// Program under proof (mini-ORM encoding of the predicate the fix emits):
//
//   def count_window_slice(m, low, high):
//       c = 0
//       k = 1
//       while k <= m:
//           if (k > low) and (k <= high):    # <-- EXACTLY the bounds the fix uses:
//               c += 1                        #     GreaterThan(win, low) & LessThanOrEqual(win, high)
//           k += 1
//       return c
//
// `count_window_slice(m, low, high)` is the number of rows the fix's window
// predicate keeps inside a single partition of size `m` (the i-th row, 1-indexed,
// has RowNumber() = i).  The contract says this equals the length of the Python
// slice `rows[low:high]`, i.e. `max(0, min(m,high) - low)` on the verified domain
// `0 <= low <= high` (Django guarantees `0 <= low_mark <= high_mark`; see SPEC.md).
//
// Closed forms use K's minInt / maxInt from the INT module.

requires "mini-orm.k"

module MINI-ORM-SPEC-SYNTAX
  imports MINI-ORM-SYNTAX
endmodule

module VERIFICATION
  imports MINI-ORM-SPEC-SYNTAX
  imports MINI-ORM
  imports MAP-SYMBOLIC
  imports K-EQUAL

  // The per-partition selected-count closed form  cf(K) = #{ j : K<=j<=M, Low<j<=High }.
  // Generalized over the loop counter K so it can serve as the loop invariant.
  syntax Int ::= cf(Int, Int, Int, Int) [function, total]   // cf(K, M, Low, High)
  rule cf(K, M, Low, High) => maxInt(0, minInt(M, High) -Int maxInt(K -Int 1, Low))
    [simplification]

  // map extensionality: closes the post-store implication (c <- V)
  rule { MM:Map [ KK <- V ] #Equals MM:Map [ KK <- V' ] } => { V #Equals V' }
    [simplification]
endmodule

module MINI-ORM-SPEC
  imports VERIFICATION

  // (WSLICE) — function contract.
  // For every m >= 0 and 0 <= low <= high, count_window_slice(m, low, high) stores
  // max(0, min(m,high) - low), i.e. the Python slice length len(rows[low:high]).
  claim
    <k> def count_window_slice ( m , low , high ) :
          { c = 0
            k = 1
            while k <= m : {
              if (k > low) and (k <= high) : { c += 1 }
              k += 1 }
            return c }
        ~> count_window_slice(M:Int, LOW:Int, HIGH:Int)
     => maxInt(0, minInt(M, HIGH) -Int LOW) ... </k>
    <funcs> _ => ?_:Map </funcs>
    requires M >=Int 0 andBool LOW >=Int 0 andBool LOW <=Int HIGH
    [all-path]

  // (WLOOP) — loop circularity (the invariant, generalized over c=C and k=K).
  // Running the loop from counter k=K with running count c=C reaches c = C + cf(K),
  // leaving k = M+1.  Side condition 1 <= K <= M+1 keeps the closed form sound
  // (for K >= M+2 the body never runs but cf would otherwise mis-count).
  claim
    <k> while k <= m : {
          if (k > low) and (k <= high) : { c += 1 }
          k += 1 } => .K ... </k>
    <store>
      c   |-> (C:Int => C +Int cf(K, M, LOW, HIGH))
      k   |-> (K:Int => M +Int 1)
      m   |-> M:Int
      low |-> LOW:Int
      high|-> HIGH:Int
    </store>
    requires M >=Int 0 andBool LOW >=Int 0 andBool LOW <=Int HIGH
     andBool K >=Int 1 andBool K <=Int M +Int 1
    [all-path]
endmodule
