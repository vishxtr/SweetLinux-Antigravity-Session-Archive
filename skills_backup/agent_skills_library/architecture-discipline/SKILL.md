---
name: architecture-discipline
description: Architectural separation of concerns, deep module boundaries, and dependency inversion.
---

# Architecture & System Discipline Framework

Enforce strict architectural separation of concerns, dependency inversion, and module boundaries.

## 1. Core Architectural Invariants
- **Layered Isolation**: Presentation components MUST NOT directly execute database queries or interact with low-level protocol drivers.
- **Dependency Inversion**: High-level business logic must depend upon abstract interfaces/seams, never on volatile vendor libraries.
- **Fail Fast & Explicit**: Do not swallow exceptions silently with empty `catch` or blanket `except Exception: pass`. Handle or wrap errors with actionable domain context.

## 2. Modularity & Deep Interfaces
- Favor deep modules: simple, robust public interfaces that conceal extensive, complex implementations.
- Avoid shallow modules where interface complexity mirrors implementation complexity.
- Test at pre-agreed boundary seams, never internal implementation trivia.
