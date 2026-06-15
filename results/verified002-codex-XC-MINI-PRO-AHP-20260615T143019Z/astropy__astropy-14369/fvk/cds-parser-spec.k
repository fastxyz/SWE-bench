requires "fvk/mini-cds-units.k"

module CDS-PARSER-SPEC
  imports MINI-CDS-UNITS

  // SPEC-PROVENANCE:
  // - from_prompt: "10+3J/m/s/kpc2" should represent continuum surface
  //   brightness with J, m, s, and kpc2 ordered as J / (m s kpc2).
  // - from_prompt: The reported bad output was "1e+3 J s / (kpc2 m)".
  // - from_code: V1 semantic action for division uses the right operand's
  //   flattened division_tail instead of its actual unit.
  claim
    <k> evalMain(scaled(p1000,
          div(unit(J),
            div(unit(m),
              div(unit(s), unit(kpc2)))))) => p1000 * (J / (m * s * kpc2)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "10-7J/s/kpc2" should keep kpc2 in the denominator.
  // - from_prompt: The reported bad output was "1e-7 J kpc2 / s".
  claim
    <k> evalMain(scaled(p1em7,
          div(unit(J),
            div(unit(s), unit(kpc2))))) => p1em7 * (J / (s * kpc2)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: Composite CDS units use repeated slash-separated
  //   denominator factors.
  // - from_default_domain: Parentheses are explicit grouping and make the
  //   grouped expression atomic to the surrounding operator.
  claim
    <k> evalMain(main(
          div(unit(J),
            paren(div(unit(m), unit(s)))))) => J / (m / s) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: Existing CDS grammar examples include "km/s",
  //   "mW/m2", and "[cm/s2]"; ordinary one-slash division is preserved.
  claim
    <k> evalMain(main(
          div(unit(km), unit(s)))) => km / s </k>
    [all-path]
endmodule
