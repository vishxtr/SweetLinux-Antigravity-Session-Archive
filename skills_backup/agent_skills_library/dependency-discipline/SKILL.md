---
name: dependency-discipline
description: Zero-unnecessary-dependency policy, lockfile determinism, and bloat prevention.
---

# Dependency Discipline Framework

Zero-unnecessary-dependency policy for high-performance, maintainable software.

## 1. Dependency Acquisition Rules
- **No Reflexive Package Adding**: Before running `npm install`, `pip install`, or `cargo add`, verify if the task can be achieved cleanly with native standard library utilities.
- **Vulnerability & Maintenance Checks**: Unmaintained packages or packages without active maintenance are strictly forbidden.
- **Single Source of Truth**: Pin dependency versions deterministically using lockfiles (`package-lock.json`, `poetry.lock`, `Cargo.lock`). Never allow unpinned wildcards in production manifests.

## 2. Runtime Overhead Minimization
- Reject micro-libraries that duplicate 5 lines of code (e.g., `is-odd`, `left-pad`).
- Ensure treeshaking compatibility on frontend bundles.
