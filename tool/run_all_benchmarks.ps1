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

New-Item -Path $ResultsDir -ItemType Directory -Force | Out-Null
New-Item -Path "dbench_records" -ItemType Directory -Force | Out-Null
New-Item -Path "local_results" -ItemType Directory -Force | Out-Null

Invoke-Step "Dependencies" {
  flutter pub get
  Assert-NativeCommand "flutter pub get"
  Install-NodeBenchmarkDeps
}

Invoke-Step "Unit tests" {
  flutter test
  Assert-NativeCommand "flutter test"
}

Invoke-Step "Analyze" {
  flutter analyze
  Assert-NativeCommand "flutter analyze"
}

Invoke-WebBenchmark -Mode "web-js" -Port 18080 -Build {
  flutter build web --release --dart-define=DBENCH_AUTORUN=true --dart-define=DBENCH_ENVIRONMENT=web-js --dart-define=DBENCH_RECORDS=$Records --dart-define=DBENCH_PAYLOAD_BYTES=$PayloadBytes
  Assert-NativeCommand "flutter build web web-js"
}

Invoke-WebBenchmark -Mode "web-wasm" -Port 18081 -Build {
  flutter build web --wasm --release --dart-define=DBENCH_AUTORUN=true --dart-define=DBENCH_ENVIRONMENT=web-wasm --dart-define=DBENCH_RECORDS=$Records --dart-define=DBENCH_PAYLOAD_BYTES=$PayloadBytes
  Assert-NativeCommand "flutter build web web-wasm"
}

Invoke-Step "Native benchmark" {
  $logPath = "local_results/native-$NativeDevice.log"
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    flutter test integration_test/benchmark_test.dart -d $NativeDevice --dart-define=DBENCH_ENVIRONMENT=native-$NativeDevice --dart-define=DBENCH_RECORDS=$Records --dart-define=DBENCH_PAYLOAD_BYTES=$PayloadBytes 2>&1 | Tee-Object -FilePath $logPath
    $nativeExitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }
  if ($nativeExitCode -ne 0) {
    throw "flutter test integration_test native failed with exit code $nativeExitCode."
  }
  $line = Select-String -Path $logPath -Pattern "DBENCH_RESULT_JSON=" | Select-Object -Last 1
  if (-not $line) {
    throw "Benchmark JSON marker was not found in $logPath."
  }
  ($line.Line -replace "^.*DBENCH_RESULT_JSON=", "") | Set-Content -NoNewline "$ResultsDir/native-$NativeDevice.json"
}

Invoke-Step "Regenerate reports" {
  dart run tool/update_readme.dart
  Assert-NativeCommand "dart run tool/update_readme.dart"
}

Invoke-Step "Validate result JSON" {
  dart run tool/validate_results.dart
  Assert-NativeCommand "dart run tool/validate_results.dart"
}
