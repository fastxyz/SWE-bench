# INTENT_SPEC

Status: constructed, not machine-checked.

1. `Point2D(Integer(1), Integer(2))` parsed through `S(...)` inside
   `evaluate(False)` must not raise the imaginary-coordinate `ValueError`.
2. The imaginary-coordinate guard should classify numeric coordinates by their
   evaluated mathematical imaginary part, not by whether `im(...)` was left as a
   truthy unevaluated object by the ambient evaluation flag.
3. Numeric coordinates with nonzero imaginary parts remain invalid.
4. Non-numeric symbolic coordinates remain accepted by this guard.
5. The repair must preserve public constructor signatures, parser behavior,
   point-level `evaluate` behavior for float rationalization, and the ambient
   evaluation flag after the temporary probe.
