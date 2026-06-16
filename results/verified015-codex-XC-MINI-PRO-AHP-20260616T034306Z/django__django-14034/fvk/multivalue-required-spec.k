requires "mini-django-forms.k"

module MULTIVALUE-REQUIRED-SPEC
  imports MINI-DJANGO-FORMS

  // SPEC-PROVENANCE:
  // - E1/E2/E3: partial-required MultiValueField must render child required
  //   attrs from child required state, not uniformly from the parent.
  claim
    <k>
      renderRequired(
        false,
        true,
        USES:Bools,
        setWidgetRequired(true, false, FIELDS:Bools)
      )
      => zipAnd(USES, FIELDS)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: require_all_fields=True keeps existing all-subwidget required
  //   rendering when the parent required attr is present.
  claim
    <k>
      renderRequired(
        true,
        true,
        USES:Bools,
        setWidgetRequired(true, true, FIELDS:Bools)
      )
      => repeatLike(true, FIELDS)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: optional parent MultiValueField can be skipped, so browser-required
  //   child attrs are absent on this render path.
  claim
    <k>
      renderRequired(
        false,
        false,
        USES:Bools,
        setWidgetRequired(false, false, FIELDS:Bools)
      )
      => repeatLike(false, FIELDS)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: reported mixed case, two text inputs that both allow HTML
  //   required; only the second subfield is required.
  claim
    <k>
      renderRequired(
        false,
        true,
        true ; true ; .Bools,
        setWidgetRequired(true, false, false ; true ; .Bools)
      )
      => false ; true ; .Bools
    </k>
    [all-path]
endmodule

