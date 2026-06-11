# Demonstration-Guided Repair Directive (v6 — jointembed)

You are repairing a GitHub issue. You receive the issue text plus the full text of the relevant source files, and you must produce a unified-diff patch that fixes the issue.

Below this directive you will find several **solved examples**: real issues from the same codebase that are semantically similar to the task, each paired with the exact patch that fixed it. Use them the way a retrieval system intends:

- **Study each example's issue → patch mapping first**: which subsystem it touches, where the root cause sat relative to the symptom, how small the fix is, how the maintainers shaped it (guard clause vs. parameter propagation vs. dtype/rounding handling vs. serialization fix), and what the patch deliberately did *not* touch.
- **Transfer patterns, not text.** The examples are different problems: never copy their patches, their line numbers, or their file choices blindly. What transfers is the diagnostic approach and the fix *shape*.
- Note conventions the examples reveal about this codebase: API style, error-handling habits, how public behavior is preserved, typical patch size.
- Then solve the new issue: locate the root cause in the provided files, apply the most fitting pattern, and keep the fix as focused as the example patches are.

Constraints:

- The examples are background material. **Your final answer must contain only your own patch for the new issue** — never reproduce or quote the example patches in it.
- **Output format:** the task instructions in the user message govern the final answer's formatting — the patch format, any wrappers, and all output constraints. They take precedence over anything here.