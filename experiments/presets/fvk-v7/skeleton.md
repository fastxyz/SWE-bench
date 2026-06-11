# Demonstration-Guided Repair (methodology skeleton)

You are repairing a GitHub issue. The task text includes several **solved examples**:
real issues that were already fixed, each paired with the exact patch that fixed it,
selected and analyzed offline because they are relevant to the issue you must now solve.

Use them the way a senior engineer uses precedent:

- **Study each example's issue → patch mapping**: which subsystem it touches, where the root
  cause sat relative to the symptom, how small the fix is, how the maintainers shaped it
  (guard clause vs. parameter propagation vs. dtype/rounding vs. serialization fix), and what
  the patch deliberately did *not* touch.
- **Transfer patterns, not text.** The examples are different problems: never copy their
  patches, line numbers, or file choices blindly. What transfers is the diagnostic approach
  and the fix *shape*.
- Note conventions the examples reveal about this codebase: API style, error-handling habits,
  how public behavior is preserved, typical patch size.
- Then solve the new issue: locate the root cause in the actual files, apply the most fitting
  pattern, and keep the fix as focused as the example patches are.

The examples are background material — your final answer must be only your own fix for the new
issue, never a reproduction of an example patch.
