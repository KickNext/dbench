# Dart Flutter Database Benchmarks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a public Flutter benchmark repository that compares local database packages and records repeatable Android, Web, and Windows results.

**Architecture:** The repository is a Flutter app plus a pure Dart benchmark engine. Runtime adapters are kept separate from the package catalog so native/codegen packages can be tracked even when a target cannot execute them in the same build.

**Tech Stack:** Flutter stable, Dart, integration_test, GitHub Actions, pub.dev package metadata.

---

### Task 1: Benchmark Engine

**Files:**
- Create: `lib/src/benchmark/database_adapter.dart`
- Create: `lib/src/benchmark/benchmark_runner.dart`
- Test: `test/benchmark_runner_test.dart`

- [x] Write failing tests for completed and skipped adapter results.
- [ ] Implement deterministic write/read/update/delete workloads.
- [ ] Run `flutter test test/benchmark_runner_test.dart`.

### Task 2: Runtime Adapters

**Files:**
- Create: `lib/src/adapters/*.dart`
- Create: `lib/src/platform/*.dart`
- Modify: `lib/main.dart`
- Create: `integration_test/benchmark_test.dart`

- [ ] Add memory, SharedPreferences, GetStorage, Hive CE, Sembast, and SQLite/sqflite adapters.
- [ ] Add a Flutter UI that can run the same benchmark engine manually.
- [ ] Add integration test output with a `DBENCH_RESULT_JSON=` marker.

### Task 3: Package Catalog And README Automation

**Files:**
- Create: `data/package_matrix.json`
- Create: `data/device_specs.json`
- Create: `tool/update_readme.dart`
- Modify: `README.md`

- [ ] Track popular Flutter database packages, including `isar_community`, Isar forks, ObjectBox, Realm, Drift, Floor, sqflite, sqlite3 wrappers, Hive/Hive CE, Sembast, Localstore, GetStorage, and SharedPreferences.
- [ ] Generate README package matrix and result tables from JSON files.
- [ ] Keep all repository-facing text in English.

### Task 4: CI And Local Runs

**Files:**
- Create: `.github/workflows/benchmarks.yml`

- [ ] Configure stable Flutter on GitHub Actions.
- [ ] Run tests and hosted Web/Windows benchmarks.
- [ ] Commit generated README/result updates back to the repository.
- [ ] Run local Android K15, Web, and Windows benchmarks and store result JSON.

### Task 5: Publish

**Files:**
- Modify: git metadata only

- [ ] Initialize git if needed.
- [ ] Create a public GitHub repository.
- [ ] Commit and push the completed benchmark repository.
