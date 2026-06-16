requires "mini-unittest-pdb.k"

module PYTEST-UNITTEST-PDB-SPEC
  imports MINI-UNITTEST-PDB

  // SPEC-PROVENANCE:
  // - from_prompt: class-level unittest.skip under --pdb must remain skipped and must not run tearDown.
  // - from_code: V1 checks _is_skipped(self._testcase), represented by CASE = true.
  claim
    <k> run(USE:Bool, ASYNC:Bool, METHOD:Bool, true) => .K ... </k>
    <explicit> false => false </explicit>
    <tdcount> 0 => 0 </tdcount>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: issue says class-level skip should match function-level skip behavior.
  // - from_public_test: method-level skip under --pdb must not call setup/teardown.
  claim
    <k> run(USE:Bool, ASYNC:Bool, true, CASE:Bool) => .K ... </k>
    <explicit> false => false </explicit>
    <tdcount> 0 => 0 </tdcount>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: non-skipped --pdb unittest tests must eventually call tearDown.
  // - from_source_comment: delay preserves debug state until pytest item teardown.
  claim
    <k> run(true, false, false, false) => .K ... </k>
    <explicit> false => false </explicit>
    <tdcount> 0 => 1 </tdcount>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: normal non-pdb behavior is not the bug.
  // - from_frame_condition: V1 does not alter the non-pdb path.
  claim
    <k> run(false, false, false, false) => .K ... </k>
    <explicit> false => false </explicit>
    <tdcount> 0 => 1 </tdcount>
    [all-path]
endmodule
