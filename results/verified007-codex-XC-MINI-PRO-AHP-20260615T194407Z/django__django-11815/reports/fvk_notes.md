# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit found no production-code gap for the public
issue's named enum-member domain. The only source change remains the V1 edit in
`repo/django/db/migrations/serializer.py`.

## Decision Trace

1. Keep enum serialization by member name.

   - Finding: F1 identifies value-constructor serialization as the public bug.
   - Proof obligations: PO2 requires `EnumClass[repr(member.name)]`; PO3 requires
     no dependency on `member.value`; PO4 requires reconstruction by enum name.
   - Decision: keep the V1 return expression using `self.value.name`.

2. Keep the import set limited to the enum class module.

   - Finding: F4 explains that value imports are unnecessary once the generated
     expression no longer mentions the value.
   - Proof obligation: PO5 requires only the enum module import.
   - Decision: keep the V1 import set `{'import %s' % module}` and do not restore
     imports from serializing `self.value.value`.

3. Leave `models.Choices` serialization unchanged.

   - Finding: F3 confirms `models.Choices` is a separate value-serialization path.
   - Proof obligations: PO1 covers registry dispatch order; PO6 covers public API
     compatibility.
   - Decision: no source edit to `ChoicesSerializer` or registry ordering.

4. Do not change tests.

   - Finding: F2 marks existing value-constructor enum expectations as SUSPECT
     public-test evidence because they encode the reported legacy behavior.
   - Proof obligations: PO6 keeps production API shape; PO8 records the benchmark
     no-execution/no-test-edit constraints.
   - Decision: no test file edits. A normal patch should update those public
     expectations separately, but this benchmark forbids that.

5. Do not run tests, Python snippets, or K tooling.

   - Finding: F5 records the proof status limitation.
   - Proof obligation: PO8 requires the honesty gate.
   - Decision: all FVK proof statements are labeled constructed, not
     machine-checked, and no test-removal recommendation is made.

## Artifacts Produced

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-python-enum-serializer.k`
- `fvk/enum-serializer-spec.k`

## Residual Risk

The proof covers named enum members importable by the existing Django migration
serializer convention. Pseudo-members without stable enum member names are not
specified by the public issue and were not used to justify further source
changes.
