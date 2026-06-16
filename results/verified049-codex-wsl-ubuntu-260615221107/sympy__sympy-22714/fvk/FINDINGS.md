# FINDINGS

Status: constructed, not machine-checked.

## F-001: V1 only forced top-level `im`, not helper evaluation

Classification: code bug in V1, fixed in V2.

Input -> observed vs expected:

- Input class: ambient `evaluate(False)`, coordinate list containing
  `residualZeroNum`, a numeric expression whose evaluated imaginary part is zero
  but whose `im.eval` path may build internal `Add`/`re`/`im` helpers.
- V1 observed by static symbolic path: `im(a, evaluate=True)` enters `im.eval`,
  but helper constructors inside `im.eval` still see ambient
  `global_parameters.evaluate == False`; a residual truthy expression can remain
  and trigger `ValueError('Imaginary coordinates are not permitted.')`.
- Expected from E-001/E-002: a coordinate with evaluated imaginary part zero is
  accepted, independent of ambient `evaluate(False)`.

Resolution: V2 wraps the whole validation probe in `with evaluate_context(True)`,
so both the top-level `im` call and helper constructors inside the probe follow
the same evaluated semantics as the normal path.

Related obligations: PO-001, PO-002, PO-005.

## F-002: Parser and `sympify` are not the root cause

Classification: rejected alternative.

Input -> observed vs expected:

- Input: the prompt's `S('Point2D(Integer(1),Integer(2))')` inside
  `evaluate(False)`.
- Observed path from source: `sympify` correctly forwards the active evaluation
  mode to `parse_expr`; the failure is raised later by `Point.__new__` during
  coordinate validation.
- Expected: repair the geometry validation boundary, not the parser.

Resolution: no parser or `sympify` source changes.

Related obligations: PO-001, PO-006.

## F-003: Existing imaginary-coordinate rejection must be preserved

Classification: compatibility constraint.

Input -> observed vs expected:

- Input class: numeric coordinates like `I`, `2*I`, or `3 + I`.
- Expected from E-003: `ValueError('Imaginary coordinates are not permitted.')`.

Resolution: V2 still raises when evaluated `im(a)` is truthy.

Related obligations: PO-003, PO-006.

## F-004: Non-numeric symbolic coordinates remain outside this guard

Classification: compatibility constraint.

Input -> observed vs expected:

- Input class: coordinates like `x`, where `a.is_number` is not true.
- Expected from E-004: this guard must not reject them.

Resolution: V2 keeps the existing `a.is_number and im(a)` structure inside the
evaluated probe.

Related obligations: PO-004, PO-006.

## F-005: Proof is constructed only

Classification: proof/test limitation.

The K artifacts and proof were constructed but not run through `kompile` or
`kprove`, and no Python/tests were executed per task constraints. Test-removal
recommendations are therefore conditional only; no tests were edited.

Related obligations: PO-007.
