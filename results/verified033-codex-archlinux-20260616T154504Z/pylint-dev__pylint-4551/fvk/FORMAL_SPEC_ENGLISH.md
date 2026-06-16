# Formal Spec English

Status: constructed for audit; no commands were executed.

This file paraphrases the nontrivial claims in `pyreverse-typehints-spec.k`.

## PARAM-ANNOTATION-COLLECTED

For an instance attribute assignment whose assigned value is a direct parameter
name, if value inference contributes `VS` and that parameter has an inferable
annotation `T`, collecting the assignment produces `VS` plus `T`.

## ANNASSIGN-COLLECTED

For an annotated assignment target, if value inference contributes `VS` and the
assignment annotation infers to `T`, collecting the assignment produces `VS`
plus `T`.

## NO-ANNOTATION-PRESERVES-VALUE-INFERENCE

If there is no assignment annotation and no parameter annotation, collecting the
assignment produces exactly the value-inference result `VS`.

## DISPLAY-BUILTIN-TYPE

After collecting a builtin `str` type alongside a `None` value, rendering
visible attribute type names with no corresponding diagram node displays the
`str` type and suppresses `NoneType`.

## DISPLAY-SUPPRESSES-DIAGRAM-NODE

If the collected type is already represented by a diagram node, the attribute
name display suppresses that type name. This mirrors current
`ClassDiagram.class_names`; associations remain possible because the raw type
node is still present in the collected map.
