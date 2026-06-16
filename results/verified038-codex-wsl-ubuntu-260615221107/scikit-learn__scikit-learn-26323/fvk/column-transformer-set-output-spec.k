requires "mini-column-transformer.k"

module COLUMN-TRANSFORMER-SET-OUTPUT-SPEC
  imports MINI-COLUMN-TRANSFORMER

  // SPEC-PROVENANCE:
  // - E1/E2: the issue says estimator-valued remainder is ignored.
  // - E5: fit_transform later clones self.remainder when remainder columns exist.
  claim [REMAINDER-PROPAGATED]:
    setOutput(ct(outDefault, estimator, outDefault, outDefault), pandas)
    => ct(outPandas, estimator, outPandas, outPandas)
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E6: clone copies _sklearn_output_config, so configuring self.remainder
  //   before fit makes the fit-time clone pandas-configured.
  claim [CLONED-REMAINDER-PANDAS]:
    cloneRemainderOutput(
      setOutput(ct(outDefault, estimator, outDefault, outDefault), pandas)
    )
    => outPandas
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E7: pandas requested plus all pandas child outputs must take the
  //   pandas concat branch instead of the ndarray branch.
  claim [PANDAS-HSTACK]:
    hstackBranch(
      outPandas,
      outPandas,
      cloneRemainderOutput(
        setOutput(ct(outDefault, estimator, outDefault, outDefault), pandas)
      )
    )
    => usePandas
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: string sentinels are not estimators.
  claim [SENTINEL-UNCHANGED]:
    setOutput(ct(outDefault, sentinel, outDefault, outDefault), pandas)
    => ct(outPandas, sentinel, outDefault, outPandas)
    [all-path]

  // SPEC-PROVENANCE:
  // - E8: transform=None is a no-op for output configuration.
  claim [NONE-NOOP]:
    setOutput(ct(outPandas, estimator, outDefault, outPandas), none)
    => ct(outPandas, estimator, outDefault, outPandas)
    [all-path]
endmodule
