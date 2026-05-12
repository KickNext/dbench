param(
  [int]$Records = 1000,
  [int]$PayloadBytes = 256,
  [string]$NativeDevice = "windows",
  [string]$ResultsDir = "results"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-Step {
  param(
    [string]$Name,
    [scriptblock]$Body
  )
  Write-Host "== $Name =="
  & $Body
}

function Assert-NativeCommand {
  param([string]$Command)
  if ($LASTEXITCODE -ne 0) {
    throw "$Command failed with exit code $LASTEXITCODE."
  }
}

function Install-NodeBenchmarkDeps {
  npm install
  Assert-NativeCommand "npm install playwright"
  npx playwright install chromium
  Assert-NativeCommand "playwright install chromium"
}

function Start-StaticServer {
  param(
    [int]$Port
  )
  $arguments = @(
    "tool/serve_web_build.cjs",
    "$Port",
    "build/web"
  )
  $process = Start-Process -FilePath "node" -ArgumentList $arguments -PassThru -WindowStyle Hidden -WorkingDirectory (Get-Location).Path
  Start-Sleep -Seconds 2
  return $process
}

function Stop-StaticServer {
  param(
    [System.Diagnostics.Process]$Process
  )
  if ($null -ne $Process -and -not $Process.HasExited) {
    Stop-Process -Id $Process.Id -Force
  }
}

function Invoke-WebBenchmark {
  param(
    [string]$Mode,
    [int]$Port,
    [scriptblock]$Build
  )
  Invoke-Step "Build $Mode" $Build
  $server = $null
  try {
    $server = Start-StaticServer -Port $Port
    node tool/run_web_benchmark.cjs "http://127.0.0.1:$Port" "$ResultsDir/$Mode.json"
    Assert-NativeCommand "node tool/run_web_benchmark.cjs $Mode"
  } finally {
    Stop-StaticServer -Process $server
  }
}

function Invoke-WindowsReleaseBenchmark {
  param(
    [int]$TimeoutSeconds = 900
  )
  if ($NativeDevice -ne "windows") {
    throw "Native public results must be generated from a release AOT app. This launcher currently supports NativeDevice=windows only."
  }

  $environment = "native-$NativeDevice"
  $stdoutPath = "local_results/$environment-release-aot.out"
  $stderrPath = "local_results/$environment-release-aot.err"
  $resultPath = "$ResultsDir/$environment.json"
  Remove-Item -LiteralPath $stdoutPath, $stderrPath -ErrorAction SilentlyContinue

  flutter build windows --release --dart-define=DBENCH_AUTORUN=true --dart-define=DBENCH_ENVIRONMENT=$environment --dart-define=DBENCH_MEASUREMENT_MODE=release-aot --dart-define=DBENCH_RECORDS=$Records --dart-define=DBENCH_PAYLOAD_BYTES=$PayloadBytes
  Assert-NativeCommand "flutter build windows release AOT"

  $exePath = "build/windows/x64/runner/Release/flutter_database_benchmarks.exe"
  if (-not (Test-Path $exePath)) {
    throw "Release executable was not found at $exePath."
  }

  $process = Start-Process -FilePath $exePath -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru -WindowStyle Hidden -WorkingDirectory (Get-Location).Path
  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  try {
    while ((Get-Date) -lt $deadline -and -not $process.HasExited) {
      Start-Sleep -Milliseconds 500
      if ((Test-Path $stdoutPath) -and (Select-String -Path $stdoutPath -Pattern "DBENCH_RESULT_JSON=" -Quiet)) {
        break
      }
    }
  } finally {
    if (-not $process.HasExited) {
      Stop-Process -Id $process.Id -Force
    }
  }

  $line = $null
  if (Test-Path $stdoutPath) {
    $line = Select-String -Path $stdoutPath -Pattern "DBENCH_RESULT_JSON=" | Select-Object -Last 1
  }
  if (-not $line) {
    $stderrTail = if (Test-Path $stderrPath) { (Get-Content $stderrPath -Tail 20) -join "`n" } else { "" }
    throw "Benchmark JSON marker was not found in $stdoutPath. Stderr tail: $stderrTail"
  }
  ($line.Line -replace "^.*DBENCH_RESULT_JSON=", "") | Set-Content -NoNewline $resultPath
}

New-Item -Path $ResultsDir -ItemType Directory -Force | Out-Null
New-Item -Path "dbench_records" -ItemType Directory -Force | Out-Null
New-Item -Path "local_results" -ItemType Directory -Force | Out-Null

Invoke-Step "Dependencies" {
  flutter pub get
  Assert-NativeCommand "flutter pub get"
  Install-NodeBenchmarkDeps
}

Invoke-Step "Core tests" {
  flutter test test/benchmark_runner_test.dart test/adapter_smoke_test.dart test/widget_test.dart
  Assert-NativeCommand "flutter test core"
}

Invoke-Step "Analyze" {
  flutter analyze
  Assert-NativeCommand "flutter analyze"
}

Invoke-WebBenchmark -Mode "web-js" -Port 18080 -Build {
  flutter build web --release --dart-define=DBENCH_AUTORUN=true --dart-define=DBENCH_ENVIRONMENT=web-js --dart-define=DBENCH_MEASUREMENT_MODE=release-web-js --dart-define=DBENCH_RECORDS=$Records --dart-define=DBENCH_PAYLOAD_BYTES=$PayloadBytes
  Assert-NativeCommand "flutter build web web-js"
}

Invoke-WebBenchmark -Mode "web-wasm" -Port 18081 -Build {
  flutter build web --wasm --no-wasm-dry-run --release --dart-define=DBENCH_AUTORUN=true --dart-define=DBENCH_ENVIRONMENT=web-wasm --dart-define=DBENCH_MEASUREMENT_MODE=release-web-wasm --dart-define=DBENCH_RECORDS=$Records --dart-define=DBENCH_PAYLOAD_BYTES=$PayloadBytes
  Assert-NativeCommand "flutter build web web-wasm"
}

Invoke-Step "Native benchmark" {
  Invoke-WindowsReleaseBenchmark
}

Invoke-Step "Regenerate reports" {
  dart run tool/update_readme.dart
  Assert-NativeCommand "dart run tool/update_readme.dart"
}

Invoke-Step "Validate result JSON" {
  dart run tool/validate_results.dart
  Assert-NativeCommand "dart run tool/validate_results.dart"
}

Invoke-Step "Full test suite" {
  flutter test
  Assert-NativeCommand "flutter test"
}
