# Dbench

Dbench is a Dart and Flutter local database benchmark suite. It tracks popular Flutter database packages, runs the same realistic scenarios on supported targets, and renders committed JSON snapshots into charts.

Open [docs/results.html](docs/results.html) to see the benchmark results visually. The README stays as a compact index: what is measured now, what is tracked but not yet measured, and where the raw data lives.

## Current Scope

- Flutter stable channel.
- Runtime targets: Flutter Web in Chrome, Flutter Linux desktop, and Flutter Windows in CI; Android physical-device runs are supported as local/private measurements.
- CI workload: deterministic balanced CRUD, read-heavy, large-payload, write-churn stress, and batched-transaction scenarios with point reads, group queries, updates, deletes, and verification reads. Pull-request and push runs are smoke-sized to keep every change reproducible; scheduled runs use a larger record count without changing scenario semantics, and manual workflow dispatch defaults to a heavier run.
- Public source of truth: committed JSON files under `results/`, regenerated into this README and `docs/results.html` by `dart run tool/update_readme.dart`.
- Packages without numbers are not counted as tested. They remain visible as explicit tracked gaps until a fair adapter, generated model, native binding, or Web asset setup exists.
- `memory_baseline`, `shared_preferences`, `get_storage`, and `hive_ce` are baselines. The HTML report has a separate SQL/document summary so key-value settings stores do not dominate database-engine comparisons.
- Local machine and physical-device measurements belong under gitignored `local_results/`.

Ops/sec is every counted operation divided by the median successful sample window. Counted operations include writes, point reads, group-query calls, updates, deletes, and verification/source reads. `open()`, `clear()`, and successful `close()`/flush work stay inside the timed window but are not added to the operation count.

## Package Matrix

<!-- DBENCH:PACKAGE_MATRIX:start -->
<details>
<summary>Tracked package matrix (19 packages)</summary>

| Package | Latest | Family | Type | Platforms | Transactions | Benchmark status |
| --- | ---: | --- | --- | --- | --- | --- |
| [isar_community](https://pub.dev/packages/isar_community) | 3.3.2 | NoSQL | NoSQL object database | Android, iOS, macOS, Windows, Linux | Read/write transactions | Tracked; adapter pending generated model wiring |
| [isar_db](https://pub.dev/packages/isar_db) | 1.0.1+1 | NoSQL | NoSQL object database | Flutter targets declared by package | Read/write transactions | Tracked; compatibility adapter pending |
| [isar](https://pub.dev/packages/isar) | 3.1.0+1 | NoSQL | NoSQL object database | Android, iOS, macOS, Windows, Linux, Web | Read/write transactions | Tracked for historical comparison |
| [objectbox](https://pub.dev/packages/objectbox) | 5.3.1 | NoSQL | NoSQL object database | Android, iOS, macOS, Windows, Linux | ACID transactions | Tracked; adapter pending generated model wiring |
| [realm](https://pub.dev/packages/realm) | 20.2.0 | NoSQL | Object database | Android, iOS, macOS, Windows, Linux | Write transactions | Tracked; adapter pending generated model wiring |
| [drift](https://pub.dev/packages/drift) | 2.33.0 | SQL | SQLite ORM/query builder | Android, iOS, macOS, Windows, Linux, Web | SQLite transactions | Runnable on native CI in this repo; Web adapter pending sqlite3 WASM assets |
| [floor](https://pub.dev/packages/floor) | 1.5.0 | SQL | SQLite persistence abstraction | Android, iOS, macOS | SQLite transactions | Tracked; adapter pending |
| [sqflite](https://pub.dev/packages/sqflite) | 2.4.2+1 | SQL | SQLite plugin | Android, iOS, macOS | SQLite transactions | Runnable on Android in this repo |
| [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | 2.4.0+3 | SQL | SQLite FFI implementation | Windows, Linux, macOS, tests | SQLite transactions | Runnable on Windows and Linux in this repo |
| [sqlite3](https://pub.dev/packages/sqlite3) | 3.3.1 | SQL | SQLite FFI bindings | Dart VM and Flutter native targets | Manual SQLite transactions | Runnable on native Flutter targets in this repo |
| [sqlite_async](https://pub.dev/packages/sqlite_async) | 0.14.1 | SQL | Async SQLite wrapper | Flutter native targets | SQLite transactions | Runnable on native CI in this repo; Web adapter pending sqlite3 WASM assets |
| [hive_ce](https://pub.dev/packages/hive_ce) | 2.19.3 | Key-value baseline | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | No general transaction model | Runnable in this repo |
| [hive](https://pub.dev/packages/hive) | 2.2.3 | Key-value baseline | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | No general transaction model | Tracked for historical comparison |
| [sembast](https://pub.dev/packages/sembast) | 3.8.7 | NoSQL | Document database | Dart VM and Flutter native targets | Single database transaction API | Runnable in this repo |
| [sembast_web](https://pub.dev/packages/sembast_web) | 2.4.4+1 | NoSQL | Document database | Web | Sembast transaction API | Runnable on Web in this repo |
| [sembast_sqflite](https://pub.dev/packages/sembast_sqflite) | 2.2.1+1 | SQL | Document database over SQLite | sqflite-supported Flutter targets | Sembast transaction API | Tracked; adapter pending |
| [get_storage](https://pub.dev/packages/get_storage) | 2.1.1 | Key-value baseline | Lightweight key-value storage | Android, iOS, macOS, Windows, Linux, Web | No transaction model | Runnable in this repo |
| [localstore](https://pub.dev/packages/localstore) | 1.4.0 | NoSQL | JSON document storage | Flutter targets declared by package | No general transaction model | Runnable in this repo |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | 2.5.5 | Key-value baseline | Platform key-value preferences | Android, iOS, macOS, Windows, Linux, Web | No transaction model | Runnable in this repo |

</details>
<!-- DBENCH:PACKAGE_MATRIX:end -->

## CI Result Source

<!-- DBENCH:DEVICE_SPECS:start -->
| Area | Value |
| --- | --- |
| README results | Committed benchmark JSON files under results/ are rendered into README.md and docs/results.html; GitHub Actions regenerates Web, Linux, and Windows snapshots on CI runs. |
| Local results | Personal machine and physical-device runs should be saved under gitignored local_results/. |
| Flutter | stable channel in GitHub Actions |
| Web CI | ubuntu-latest runner, Flutter Web release build, Chrome; push/pull_request smoke runs use DBENCH_RECORDS=100, scheduled stress runs use DBENCH_RECORDS=2000, manual dispatch defaults to 10000 |
| Linux CI | ubuntu-latest runner, Flutter Linux desktop integration test target; push/pull_request smoke runs use DBENCH_RECORDS=100, scheduled stress runs use DBENCH_RECORDS=2000, manual dispatch defaults to 10000 |
| Windows CI | windows-latest runner, Flutter Windows desktop test target; push/pull_request smoke runs use DBENCH_RECORDS=100, scheduled stress runs use DBENCH_RECORDS=2000, manual dispatch defaults to 10000 |
| Android | Not published in README because GitHub-hosted runners do not provide the physical device used for local measurements |
<!-- DBENCH:DEVICE_SPECS:end -->

## CI Performance Overview

<!-- DBENCH:CI_VISUALIZATION:start -->
Open [docs/results.html](docs/results.html) for the visual dashboard with SVG charts and cross-target tables.

Committed result snapshots currently present: `web`, `windows`.
`linux` is configured in GitHub Actions but no Linux JSON snapshot is committed in this checkout yet. It should appear only after a real Linux workflow run generates `results/linux.json`.

Measured packages in committed snapshots: 10 of 19. The remaining packages are explicit adapter/platform gaps, not hidden benchmark numbers.

### Coverage Snapshot

| Environment | Completed adapters | Skipped rows | Failed rows |
| --- | --- | ---: | ---: |
| web | `get_storage`, `hive_ce`, `localstore`, `sembast_web`, `shared_preferences` | 76 | 0 |
| windows | `drift`, `get_storage`, `hive_ce`, `localstore`, `sembast`, `shared_preferences`, `sqflite_common_ffi`, `sqlite3`, `sqlite_async` | 56 | 0 |

### Tracked But Not Yet Measured

`floor`, `hive`, `isar`, `isar_community`, `isar_db`, `objectbox`, `realm`, `sembast_sqflite`, `sqflite`

Reasons are kept in the package matrix and raw JSON: generated object-model adapters (`isar*`, `objectbox`, `realm`, `floor`), Web SQLite WASM/worker assets (`drift`, `sqlite_async` on Web), platform-only adapters (`sqflite` on Android/iOS/macOS), or compatibility adapters still pending (`sembast_sqflite`, legacy `hive`).

### Fastest Rows

| Environment | Scenario | Fastest SQL/document adapter | Fastest persistent adapter | Completed | Skipped | Failed |
| --- | --- | --- | --- | ---: | ---: | ---: |
| web | batched_transaction | - | - | 0 | 20 | 0 |
| web | crud_balanced | `localstore` 33,042 ops/sec | `shared_preferences` 97,368 ops/sec | 6 | 14 | 0 |
| web | large_payload | `localstore` 10,145 ops/sec | `shared_preferences` 67,764 ops/sec | 6 | 14 | 0 |
| web | read_heavy | `localstore` 53,499 ops/sec | `shared_preferences` 122,000 ops/sec | 6 | 14 | 0 |
| web | write_churn_stress | `localstore` 20,144 ops/sec | `shared_preferences` 136,585 ops/sec | 6 | 14 | 0 |
| windows | batched_transaction | `sqlite3` 15,337 ops/sec | `sqlite3` 15,337 ops/sec | 4 | 16 | 0 |
| windows | crud_balanced | `sqlite_async` 2,544 ops/sec | `get_storage` 62,648 ops/sec | 10 | 10 | 0 |
| windows | large_payload | `sqlite_async` 2,921 ops/sec | `get_storage` 103,397 ops/sec | 10 | 10 | 0 |
| windows | read_heavy | `sqlite_async` 3,065 ops/sec | `get_storage` 134,717 ops/sec | 10 | 10 | 0 |
| windows | write_churn_stress | `sqlite_async` 4,234 ops/sec | `get_storage` 105,204 ops/sec | 10 | 10 | 0 |
<!-- DBENCH:CI_VISUALIZATION:end -->

## Results

<!-- DBENCH:BENCHMARK_RESULTS:start -->
The readable dashboard is [docs/results.html](docs/results.html). Raw machine-readable snapshots stay in `results/*.json` instead of being duplicated into README tables.

Measured packages across committed snapshots: 10 of 19.

| Environment | JSON source | Generated | Scenario rows | Measured packages |
| --- | --- | --- | ---: | ---: |
| web | [`results/web.json`](results/web.json) | `2026-05-11T13:35:16.083Z` | 100 | 5 |
| windows | [`results/windows.json`](results/windows.json) | `2026-05-11T13:34:45.105870Z` | 100 | 9 |
<!-- DBENCH:BENCHMARK_RESULTS:end -->

## Isolate Behavior

This section checks whether a database can be reopened from a separate Dart isolate after the main isolate writes and closes the store. It does not yet prove concurrent multi-isolate write safety or package-specific worker APIs. It is intentionally separate from throughput because isolate behavior is a capability and architecture signal, not just a speed metric.

<!-- DBENCH:ISOLATE_RESULTS:start -->
<details>
<summary>Isolate sharing probe rows</summary>

| Environment | Database | Status | Shared read across isolates | Notes |
| --- | --- | --- | --- | --- |
| web | all | skipped | not tested | Flutter Web does not expose Dart VM isolates for this benchmark. |
| windows | memory_baseline | completed | no | Dart isolates have separate heaps; in-memory maps are not shared. |
| windows | hive_ce | completed | yes | Separate isolate reopened the same box path and read the main isolate record. |
| windows | sembast | completed | yes | Separate isolate reopened the same database file and read the main isolate record. |
| windows | sqflite_common_ffi | completed | yes | Separate isolate reopened the same SQLite file through sqflite_common_ffi and read the main isolate record. |
| windows | sqlite3 | skipped | not tested | Runnable adapter exists, but direct sqlite3 isolate reopening is not probed yet. |
| windows | shared_preferences | skipped | not tested | Plugin-backed storage is not probed from a background isolate. |
| windows | get_storage | skipped | not tested | Flutter/widget-bound package; isolate sharing needs a dedicated adapter. |
| windows | localstore | skipped | not tested | Runnable adapter exists, but file-backed isolate sharing is not probed yet. |

</details>
<!-- DBENCH:ISOLATE_RESULTS:end -->

## Running Locally

```bash
flutter pub get
flutter test
flutter analyze
mkdir -p local_results
flutter test integration_test/benchmark_test.dart -d windows --dart-define=DBENCH_RECORDS=1000
flutter build web --release --dart-define=DBENCH_AUTORUN=true --dart-define=DBENCH_RECORDS=1000
node tool/run_web_benchmark.cjs http://127.0.0.1:18080 local_results/web.json
flutter test integration_test/benchmark_test.dart -d <android-device-id> --dart-define=DBENCH_RECORDS=1000
```

Each benchmark run prints a `DBENCH_RESULT_JSON=` line. Save personal runs into `local_results/<environment>.json`; keep `results/` reserved for CI output that is meant to update the public README.

## Adding A Database Adapter

1. Add the package to `data/package_matrix.json`.
2. Implement `DatabaseAdapter` in `lib/src/adapters/`.
3. Register it in `availableAdapters()`.
4. Keep native or code-generated packages isolated so unsupported targets report `skipped` instead of breaking the whole suite.
5. Run the unit test, analyze, and every target that the package claims to support.
