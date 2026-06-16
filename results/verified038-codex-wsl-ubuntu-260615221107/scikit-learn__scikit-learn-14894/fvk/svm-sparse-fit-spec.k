requires "mini-python-numpy.k"

module SVM-SPARSE-FIT-SPEC-SYNTAX
  imports MINI-PYTHON-NUMPY-SYNTAX

  syntax Id ::= "n_class"           [token]
              | "n_SV"              [token]
              | "dual_coef_indptr"  [token]
endmodule

module SVM-SPARSE-FIT-VERIFICATION
  imports MINI-PYTHON-NUMPY
  imports SVM-SPARSE-FIT-SPEC-SYNTAX
  imports K-EQUAL
  imports MAP-SYMBOLIC
endmodule

module SVM-SPARSE-FIT-SPEC
  imports SVM-SPARSE-FIT-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "empty support_vectors_" and "No error is thrown" =>
  //   n_SV == 0 is in-domain for the reconstruction.
  // - from_prompt: "self.dual_coef_ = sp.csr_matrix([])" => empty CSR rows
  //   must be representable by an all-zero indptr.
  // - from_docs: SVR has dual_coef_ shape [1, n_SV]; SVC/NuSVC have
  //   [n_class-1, n_SV] => shape is (n_class, n_SV).
  // - from_code: BaseSVC rejects fewer than two classes, and regressors use
  //   n_class = 1, so the reconstruction has n_class >= 1.
  claim
    <k> dual_coef_indptr = arange(n_class + 1) * n_SV => .K ... </k>
    <store>
      n_class |-> NC:Int
      n_SV |-> NSV:Int
      dual_coef_indptr |-> (_ => scale(range(0, NC +Int 1), NSV))
    </store>
    requires NC >=Int 1 andBool NSV >=Int 0
    [all-path]
endmodule
