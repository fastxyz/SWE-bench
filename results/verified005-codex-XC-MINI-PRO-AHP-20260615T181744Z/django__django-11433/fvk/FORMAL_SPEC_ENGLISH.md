# Formal Spec English Paraphrase

The formal claims in `construct-instance-spec.k` model one eligible-or-skipped
field at a time. The loop in `construct_instance()` is represented by the frame
condition that each field's decision is independent, with file fields producing
a queue action instead of immediate assignment.

## Claim Paraphrases

`CI-DERIVED-NONEMPTY-ASSIGNS`: For any eligible non-file model field with a
default, if the widget reports that the field was omitted from submitted data
but the cleaned value is not empty, the decision is to assign that cleaned value
to the model instance.

`CI-DERIVED-FILE-QUEUES`: For any eligible file model field with a default, if
the widget reports that the field was omitted from submitted data but the
cleaned value is not empty, the decision is to queue the file field for the
existing delayed save path.

`CI-OMITTED-EMPTY-PRESERVES-DEFAULT`: For any eligible model field with a
default, if the widget reports that the field was omitted and the cleaned value
is empty, the decision is to skip assignment so the model default remains.

`CI-SUBMITTED-EMPTY-ASSIGNS`: For any eligible non-file model field with a
default, if the widget reports that the field was not omitted, an empty cleaned
value is still assigned.

`CI-NONDEFAULT-OMITTED-EMPTY-ASSIGNS`: For any eligible non-file field without a
model default, omission does not trigger default preservation; the cleaned value
is assigned.

`CI-INELIGIBLE-*`: If a field is not editable, is an `AutoField`, is absent
from `cleaned_data`, is not allowed by `fields`, or is excluded by `exclude`,
the decision is to skip that field.

## Frame Conditions

F1. The model field's own `has_default()`, the widget's
`value_omitted_from_data()` result, and the form field's `empty_values` determine
whether the default-preservation skip applies.

F2. The public function signature and hook signatures are unchanged.

F3. The proof is partial correctness over the assignment decision. No
termination proof is needed for the finite Django metadata loop because the
issue and patch do not alter loop bounds or iteration.
