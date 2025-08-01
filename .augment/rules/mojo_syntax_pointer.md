---
type: "always_apply"
---

# Mojo Syntax Reference & Coding Standards
- Do not add comments that are unnecessary or overexplaining.
- Remove comments that are obsolete or necessary for understanding the code.
- When creating, modifying, or validating Mojo source files, adhere to design patterns/guidelines captured in `mojo_syntax.md`.
- Run `update_mojo_syntax.mojo` automation script to systematically review and correct Mojo syntax issues for design pattern compliance.
- Fix all errors found by `update_mojo_syntax.mojo`.
- Fix compiler errors and warnings not detected by the automation script.