# Intent Spec

This file records public intent before accepting candidate behavior as the
specification.

## Required behavior

1. A user can call `ab.set_gid('My_label')` on an `AnnotationBbox` and then save
   the figure as SVG.
2. If the annotation is rendered, the SVG output must expose the parent
   `AnnotationBbox` gid so the annotation can be found later in SVG editing.
3. Because `AnnotationBbox` is a composite artist, the intended SVG form is a
   group wrapping the whole annotation, not a copied id on only one child.
4. The group must enclose all rendered pieces of the annotation: the optional
   arrow, frame patch, and contained offset box/image.
5. This metadata fix must preserve normal rendering behavior: skipped
   annotations remain skipped, child draw order remains unchanged, and existing
   renderer APIs remain compatible.

## Domain assumptions

- The relevant gid obligation is for a truthy user-supplied gid such as
  `My_label`.
- The relevant output path is a successful SVG save.
- Partial correctness is sufficient for this audit; termination and exception
  cleanup are not proved.
