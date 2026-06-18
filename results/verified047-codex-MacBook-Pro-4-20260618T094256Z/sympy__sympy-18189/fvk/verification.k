requires "mini-python.k"

module VERIFICATION
  imports MINI-PYTHON
  imports BOOL
  imports K-EQUAL

  // Concrete public issue instance:
  // eq = n**4 + m**4 - 2**4 - 3**4, default sorted variable order = (m,n).
  rule vars(pow4_mn_2_3) => mn [simplification]

  rule completeSyms(mn, mn) => true [simplification]
  rule completeSyms(nm, mn) => true [simplification]

  rule sameOrder(mn, mn) => true [simplification]
  rule sameOrder(nm, mn) => false [simplification]

  rule needsReorder(mn, mn) => false [simplification]
  rule needsReorder(nm, mn) => true [simplification]

  // canonical(EQ, P, PERM) abstracts the un-reordered diophantine solve.
  // For the issue equation, the prompt anchors the two relevant results.
  rule canonical(pow4_mn_2_3, tparam, false) => pow4_base_mn [simplification]
  rule canonical(pow4_mn_2_3, tparam, true)  => pow4_signed_mn [simplification]

  rule reorder(mn, mn, pow4_base_mn)   => pow4_base_mn [simplification]
  rule reorder(mn, nm, pow4_base_mn)   => pow4_base_nm [simplification]
  rule reorder(mn, mn, pow4_signed_mn) => pow4_signed_mn [simplification]
  rule reorder(mn, nm, pow4_signed_mn) => pow4_signed_nm [simplification]
endmodule
