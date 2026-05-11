# Dbench

Dbench is a Dart and Flutter local database benchmark suite. It tracks popular Flutter database packages, documents their tradeoffs, and runs the same write/read/update/delete workload on Android, Web, and Windows targets where an adapter is available.

The repository is intentionally benchmark-first: package claims are not treated as results until the benchmark harness can run them and commit JSON output.

## Current Scope

- Flutter stable: 3.41.9 locally, `stable` channel in CI.
- Runtime targets: Android physical device, Flutter Web in Chrome, and Flutter Windows.
- Workload: deterministic record insert, point read, update, and delete loops.
- Result source of truth: JSON files under `results/`, rendered into this README by `dart run tool/update_readme.dart`.

## Package Matrix

<!-- DBENCH:PACKAGE_MATRIX:start -->
| Package | Latest | Type | Platforms | Transactions | Benchmark status |
| --- | ---: | --- | --- | --- | --- |
| [isar_community](https://pub.dev/packages/isar_community) | 3.3.2 | NoSQL object database | Android, iOS, macOS, Windows, Linux, Web | Read/write transactions | Tracked; adapter pending generated model wiring |
| [isar_db](https://pub.dev/packages/isar_db) | 1.0.1+1 | NoSQL object database | Flutter targets declared by package | Read/write transactions | Tracked; compatibility adapter pending |
| [isar](https://pub.dev/packages/isar) | 3.1.0+1 | NoSQL object database | Android, iOS, macOS, Windows, Linux, Web | Read/write transactions | Tracked for historical comparison |
| [objectbox](https://pub.dev/packages/objectbox) | 5.3.1 | NoSQL object database | Android, iOS, macOS, Windows, Linux | ACID transactions | Tracked; adapter pending generated model wiring |
| [realm](https://pub.dev/packages/realm) | 20.2.0 | Object database | Android, iOS, macOS, Windows, Linux | Write transactions | Tracked; adapter pending generated model wiring |
| [drift](https://pub.dev/packages/drift) | 2.33.0 | SQLite ORM/query builder | Android, iOS, macOS, Windows, Linux, Web | SQLite transactions | Tracked; adapter pending |
| [floor](https://pub.dev/packages/floor) | 1.5.0 | SQLite persistence abstraction | Android, iOS, macOS | SQLite transactions | Tracked; adapter pending |
| [sqflite](https://pub.dev/packages/sqflite) | 2.4.2+1 | SQLite plugin | Android, iOS, macOS | SQLite transactions | Runnable on Android in this repo |
| [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | 2.4.0+3 | SQLite FFI implementation | Windows, Linux, macOS, tests | SQLite transactions | Runnable on Windows in this repo |
| [sqlite3](https://pub.dev/packages/sqlite3) | 3.3.1 | SQLite FFI bindings | Dart VM and Flutter native targets | Manual SQLite transactions | Tracked; direct adapter pending |
| [sqlite_async](https://pub.dev/packages/sqlite_async) | 0.14.1 | Async SQLite wrapper | Flutter native targets | SQLite transactions | Tracked; adapter pending |
| [hive_ce](https://pub.dev/packages/hive_ce) | 2.19.3 | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | No general transaction model | Runnable in this repo |
| [hive](https://pub.dev/packages/hive) | 2.2.3 | Key-value / typed boxes | Android, iOS, macOS, Windows, Linux, Web | No general transaction model | Tracked for historical comparison |
| [sembast](https://pub.dev/packages/sembast) | 3.8.7 | Document database | Dart VM and Flutter native targets | Single database transaction API | Runnable in this repo |
| [sembast_web](https://pub.dev/packages/sembast_web) | 2.4.4+1 | Document database | Web | Sembast transaction API | Runnable on Web in this repo |
| [sembast_sqflite](https://pub.dev/packages/sembast_sqflite) | 2.2.1+1 | Document database over SQLite | sqflite-supported Flutter targets | Sembast transaction API | Tracked; adapter pending |
| [get_storage](https://pub.dev/packages/get_storage) | 2.1.1 | Lightweight key-value storage | Android, iOS, macOS, Windows, Linux, Web | No transaction model | Runnable in this repo |
| [localstore](https://pub.dev/packages/localstore) | 1.4.0 | JSON document storage | Flutter targets declared by package | No general transaction model | Tracked; adapter pending |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | 2.5.5 | Platform key-value preferences | Android, iOS, macOS, Windows, Linux, Web | No transaction model | Runnable in this repo |
<!-- DBENCH:PACKAGE_MATRIX:end -->

## Test Device And Toolchain

The Android device name is recorded as hardware metadata only. It is not used as a result column.

<!-- DBENCH:DEVICE_SPECS:start -->
| Area | Value |
| --- | --- |
| Android test device | K15 (rockchip, rk3568_r) |
| Android hardware | Rockchip RK3568 EVB1 DDR4 V10 Board |
| Android OS | Android 11 / API 30 |
| Android CPU | 4 x ARM Cortex-A55 class cores (CPU part 0xd05) |
| Android memory | 3984488 kB total, 1992240 kB swap |
| Android display | 1366x768 at 160 dpi |
| Flutter | 3.41.9 stable |
| Dart | 3.11.5 |
| Windows | Microsoft Windows 10.0.26200.8328 |
| Chrome | 148.0.7778.96 |
| Edge | 147.0.3912.98 |
<!-- DBENCH:DEVICE_SPECS:end -->

## Results

<!-- DBENCH:BENCHMARK_RESULTS:start -->
| Environment | Database | Status | Records | Payload | Total ops | Ops/sec | Notes |
| --- | --- | --- | ---: | ---: | ---: | ---: | --- |
| android | memory_baseline | completed | 1000 | 256 | 4000 | 7509 |  |
| android | shared_preferences | completed | 1000 | 256 | 4000 | 40 |  |
| android | get_storage | completed | 1000 | 256 | 4000 | 2252 |  |
| android | hive_ce | completed | 1000 | 256 | 4000 | 294 |  |
| android | sembast | completed | 1000 | 256 | 4000 | 85 |  |
| android | sqflite | completed | 1000 | 256 | 4000 | 235 |  |
| web | memory_baseline | completed | 1000 | 256 | 4000 | 380952 |  |
| web | shared_preferences | completed | 1000 | 256 | 4000 | 44843 |  |
| web | get_storage | completed | 1000 | 256 | 4000 | 612 |  |
| web | hive_ce | completed | 1000 | 256 | 4000 | 2349 |  |
| web | sembast | completed | 1000 | 256 | 4000 | 932 |  |
| web | sqflite_sqlite | skipped | 1000 | 256 | 0 | 0 | SQLite adapter is not available on this target. |
| windows | memory_baseline | completed | 1000 | 256 | 4000 | 89411 |  |
| windows | shared_preferences | completed | 1000 | 256 | 4000 | 233 |  |
| windows | get_storage | completed | 1000 | 256 | 4000 | 30833 |  |
| windows | hive_ce | completed | 1000 | 256 | 4000 | 349 |  |
| windows | sembast | completed | 1000 | 256 | 4000 | 141 |  |
| windows | sqflite_common_ffi | completed | 1000 | 256 | 4000 | 54 |  |
<!-- DBENCH:BENCHMARK_RESULTS:end -->

## Running Locally

```bash
flutter pub get
flutter test
flutter analyze
flutter test integration_test/benchmark_test.dart -d windows --dart-define=DBENCH_RECORDS=1000
flutter build web --release --dart-define=DBENCH_AUTORUN=true --dart-define=DBENCH_RECORDS=1000
node tool/run_web_benchmark.cjs http://127.0.0.1:18080 results/web.json
flutter test integration_test/benchmark_test.dart -d <android-device-id> --dart-define=DBENCH_RECORDS=1000
dart run tool/update_readme.dart
```

Each benchmark run prints a `DBENCH_RESULT_JSON=` line. Save that JSON into `results/<environment>.json`, then run the README updater.

## Adding A Database Adapter

1. Add the package to `data/package_matrix.json`.
2. Implement `DatabaseAdapter` in `lib/src/adapters/`.
3. Register it in `availableAdapters()`.
4. Keep native or code-generated packages isolated so unsupported targets report `skipped` instead of breaking the whole suite.
5. Run the unit test, analyze, and every target that the package claims to support.
