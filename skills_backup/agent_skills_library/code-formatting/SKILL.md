---
name: code-formatting
description: Deterministic code formatting, static analysis, type rigor, and zero dead code.
---

# Code Formatting & Anti-Regression Discipline

Enforce deterministic code formatting, static analysis validation, and zero dead code.

## 1. Automated Standards
- Code must pass configured linters (ESLint, Biome, Ruff, Clippy) without suppression directives (`eslint-disable`, `# noqa`) unless accompanied by an explicit issue justification.
- Whitespace and formatting must strictly match existing codebase conventions.
- Remove all debugging prints, stray console logs, and temporary commented-out code blocks before committing.

## 2. Type Rigor
- Do not use `any` or escape hatches to bypass type errors. Model proper sum types, interfaces, or generics.
- Keep tests green at every step: never break existing unit tests to add a feature.
