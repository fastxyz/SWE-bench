# FVK Findings

Status: findings are derived from public issue evidence, source inspection, and
constructed proof obligations. No tests, Python, or K tooling were run.

## F-001: V1 discharges the reported NumPy warning mechanism

Input -> observed vs expected:

- Pre-fix input: default `N == 256`, `X = np.empty((0,), dtype=np.uint8)`.
- Pre-fix observed: the code assigns sentinels 257, 256, and 258 into a
  `uint8` `xa`, which NumPy 1.24 warns will stop being allowed.
- Expected: no warnings.
- V1 behavior by inspection: `np.iinfo(uint8).max == 255`, so
  `self._i_bad == 258` triggers promotion before the sentinel assignments.

Classification: code bug fixed by V1.

Relevant proof obligations: PO-001, PO-002, PO-004.

Decision: keep V1's promotion guard.

## F-002: V1 fixes the underlying special-index bug, not only the empty case

Input -> observed vs expected:

- Pre-fix representative input: an integer array whose dtype cannot represent
  `N + 2`, with at least one bad, under, or over element.
- Pre-fix observed: assigning the special index can wrap or warn before
  `lut.take(...)`, so the value may become an ordinary colormap index.
- Expected: bad, under, and over values use the dedicated lookup-table entries.
- V1 behavior by inspection: the dtype promotion happens before all three
  sentinel assignments, so those assignments store the actual special indices.

Classification: code bug fixed by V1.

Relevant proof obligations: PO-001, PO-002, PO-003.

Decision: no additional source edit required for this class.

## F-003: Explicit modulo wrapping is rejected

Input -> observed vs expected:

- Candidate alternative: preserve legacy overflow by reducing sentinels modulo
  the input dtype range.
- Observed under the alternative: `N + 2` for default `N == 256` and `uint8`
  would select ordinary index 2 rather than the bad sentinel index 258.
- Expected: special cases select the special lookup-table rows.

Classification: rejected alternative; would preserve the defect.

Relevant proof obligations: PO-002, PO-003.

Decision: do not replace V1 with modulo arithmetic.

## F-004: No public compatibility problem found in V1

Input -> observed vs expected:

- Public call shape: `Colormap.__call__(X, alpha=None, bytes=False)`.
- V1 observed by inspection: the public signature, scalar-vs-array return
  branch, `bytes`, `alpha`, and `lut.take(...)` calls are unchanged.
- Expected: the fix should be limited to internal index preparation.

Classification: compatibility confirmation.

Relevant proof obligations: PO-005, PO-006.

Decision: keep V1 scoped to the integer dtype promotion.

## F-005: Residual proof boundary is the NumPy promotion model, not a source bug

Input -> observed vs expected:

- Proof slice: NumPy dtype capacity and `np.promote_types(...)` behavior are
  modeled abstractly as producing an integer dtype with capacity at least
  `self._i_bad` for practical colormap sizes.
- Expected for this FVK run: constructed proof only; no `kprove`, NumPy, or
  Python execution.

Classification: proof capability / model boundary.

Relevant proof obligations: PO-007.

Decision: do not change code for this boundary. Keep tests until the proof is
machine-checked and runtime tests are available in a normal environment.
