# Changelog

All notable changes to the `distributed-systems-patterns` skill are recorded here. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-05-06

### Changed (BREAKING - path layout)

All artifact paths moved under a per-feature folder. The previous scattered-by-artifact-type layout (docs/designs/, docs/contracts/, schemas/, asyncapi/, docs/runbooks/, docs/launches/, docs/services/) is replaced by `docs/features/<slug>/{design.md,adrs/,contracts/,schemas/,asyncapi/,runbooks/,launches/}`. Each feature now owns one folder containing all its artifacts. Cross-links inside a feature become sibling/child paths instead of `../../...` traversals.

ADRs split into feature-scoped (default, under `docs/features/<slug>/adrs/`) and platform-wide (under `docs/system/adrs/`). NNNN numbering is per-folder.

### Migration

Existing v0.2 installations: run `bash scripts/migrate-layout.sh` from the repo root after updating to v0.3.0. The script moves files into the new layout using `git mv` so history is preserved. Manual review needed afterward to identify which ADRs should move to `docs/system/adrs/` (platform-wide) vs stay under their feature.

### Why

The old layout scattered each feature's artifacts across 5+ root directories. With multiple features the root tree grew unwieldy. The new layout groups everything for one feature in one folder, so a reader can `cd docs/features/<slug>/` and see design + contracts + ADRs + runbooks + launches as siblings.
