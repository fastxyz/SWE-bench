// combine-aliasing.k
// =============================================================================
// Mini-X (fragment) K semantics for the part of django/db/models/sql/query.py
// Query.combine() that is relevant to ticket django-15128: the loop that builds
// the `change_map` (rhs-alias -> new-alias) which is later handed to
// change_aliases() / relabel_aliases().
//
// STATUS: constructed, NOT machine-checked (FVK MVP: no kompile/kprove run).
//
// ----------------------------------------------------------------------------
// What we abstract, and faithfully so
// ----------------------------------------------------------------------------
// A SQL alias in Query is one of two shapes (see Query.table_alias):
//   * a GENERATED alias  "<prefix><number>"  -- e.g. "T4", "U1"
//       (built as '%s%d' % (self.alias_prefix, len(self.alias_map)+1))
//   * a TABLE-NAME alias -- the bare db_table on a table's FIRST occurrence
// We model them as the constructors:
//       pref(P, N)   for the generated alias <P><N>   (P an Id like T/U/V)
//       name(S)      for the table-name alias S
// Equality is purely syntactic (constructor) equality, which matches Python's
// string equality on the real aliases:
//       pref(P,N) == pref(Q,M)  <=>  P==Q and N==M
//       pref(_,_) == name(_)    is always false   (a digit-bearing generated
//                                                   alias never equals a bare
//                                                   table name)
//
// The combine loop (repo lines 619-633), abstracted:
//
//     change_map = {}                      # <cmap>
//     for alias in rhs_tables:             # <pairs>: a stream of pair(K,V)
//         new_alias = self.join(...)       #   V = self.join's result
//         if alias != new_alias:           #   the `if alias != new_alias` guard
//             change_map[alias] = new_alias
//
// The choice of new_alias (self.join -> reuse-or-table_alias) is abstracted into
// the input stream <pairs>: each element pair(K, V) carries the rhs alias K (a
// loop key) and the value V that self.join returns for it. The DOMAIN facts that
// make the proof go through -- "every K is pref(Pr,_)" and "every V is pref(Ps,_)
// or name(_)" -- are established by callers (the guard + bump_prefix and the
// shape of self.join); they appear as the claim's `requires` and are justified in
// PROOF_OBLIGATIONS.md (PO-KEYS, PO-VALS, PO-PREFIX).
// =============================================================================

module COMBINE-ALIASING-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX

  // An alias: a generated "<P><N>" alias, or a bare table-name alias.
  syntax Alias ::= "pref" "(" Id "," Int ")"
                 | "name" "(" Id ")"

  // One iteration's recorded mapping (rhs key |-> value returned by self.join).
  syntax Pair  ::= "pair" "(" Alias "," Alias ")"

  // Driver statement: run the change_map-building loop to completion.
  syntax Stmt  ::= "buildChangeMap"

  syntax KResult ::= Alias
endmodule

module COMBINE-ALIASING
  imports COMBINE-ALIASING-SYNTAX
  imports INT
  imports BOOL
  imports MAP
  imports LIST
  imports K-EQUAL

  configuration
    <k>     $PGM:Stmt </k>
    <pairs> $IN:List   </pairs>   // remaining pair(K,V), the rhs_tables stream
    <cmap>  .Map       </cmap>    // the change_map being built: Alias |-> Alias

  // --- loop body, "recorded" branch: alias != new_alias  (repo line 632-633) --
  rule <k> buildChangeMap ... </k>
       <pairs> ListItem(pair(K:Alias, V:Alias)) => .List ... </pairs>
       <cmap>  M:Map => M[K <- V] </cmap>
    requires notBool (K ==K V)

  // --- loop body, "skipped" branch: alias == new_alias (self-map, not added) ---
  rule <k> buildChangeMap ... </k>
       <pairs> ListItem(pair(K:Alias, V:Alias)) => .List ... </pairs>
       <cmap>  M:Map => M </cmap>
    requires K ==K V

  // --- loop exit: no more rhs aliases to process ------------------------------
  rule <k> buildChangeMap => .K ... </k>
       <pairs> .List </pairs>
endmodule
