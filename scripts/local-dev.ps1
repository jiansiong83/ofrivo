[CmdletBinding()]
param(
    [ValidateSet('start', 'status', 'reset', 'lint', 'health', 'integration', 'adb-reverse', 'admin', 'emulator', 'device', 'apk', 'validate')]
    [string]$Command = 'status'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$MobileRoot = Join-Path $RepoRoot 'apps/mobile'
$AdminRoot = Join-Path $RepoRoot 'apps/admin'
$SupabaseCli = 'npx.cmd'
$SupabasePackage = 'supabase@2.109.1'
$FlutterExe = if ($env:OFRIVO_FLUTTER_BIN) {
    $env:OFRIVO_FLUTTER_BIN
} else {
    'F:\Dev\FlutterSDK\bin\flutter.bat'
}

function Invoke-Supabase {
    param([string[]]$Arguments)

    Push-Location $RepoRoot
    try {
        $previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $output = @(& $SupabaseCli --yes $SupabasePackage @Arguments 2>&1)
        $nativeExitCode = $LASTEXITCODE
        $ErrorActionPreference = $previousErrorActionPreference
        if ($nativeExitCode -ne 0) {
            $output | Write-Error
            throw "Supabase command failed: $($Arguments -join ' ')"
        }
        return $output
    } finally {
        Pop-Location
    }
}

function Get-LocalSupabaseEnvironment {
    $lines = @(Invoke-Supabase -Arguments @('status', '--output', 'env'))
    $values = @{}
    foreach ($line in $lines) {
        if ($line -match '^(?<key>[A-Z][A-Z0-9_]*)="(?<value>.*)"$') {
            $values[$matches.key] = $matches.value
        }
    }
    foreach ($required in @('API_URL', 'ANON_KEY', 'STUDIO_URL', 'MAILPIT_URL')) {
        if (-not $values.ContainsKey($required)) {
            throw "Local Supabase status did not contain $required. Run supabase start first."
        }
    }
    return $values
}

function Write-LocalStatus {
    $localEnv = Get-LocalSupabaseEnvironment
    Write-Output "API/Auth/Storage: $($localEnv.API_URL)"
    Write-Output "PostgreSQL: 127.0.0.1:54422"
    Write-Output "Studio: $($localEnv.STUDIO_URL)"
    Write-Output "Mailpit: $($localEnv.MAILPIT_URL)"
    Write-Output 'Anon key: available only to the current process (not printed)'
    Write-Output 'Service role: not passed to Flutter'
}

function Invoke-LocalHealth {
    $localEnv = Get-LocalSupabaseEnvironment
    $anonKey = $localEnv.ANON_KEY
    $headers = @{ apikey = $anonKey; Authorization = "Bearer $anonKey" }
    $targets = @(
        @{ Name = 'API Auth health'; Url = "$($localEnv.API_URL)/auth/v1/health"; Headers = @{} },
        @{ Name = 'REST public API'; Url = "$($localEnv.API_URL)/rest/v1/"; Headers = $headers },
        @{ Name = 'Studio'; Url = $localEnv.STUDIO_URL; Headers = @{} },
        @{ Name = 'Mailpit'; Url = $localEnv.MAILPIT_URL; Headers = @{} }
    )

    foreach ($target in $targets) {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri $target.Url -Headers $target.Headers -TimeoutSec 10
            Write-Output "$($target.Name): PASS HTTP $($response.StatusCode)"
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            if ($statusCode) {
                throw "$($target.Name): HTTP $statusCode"
            }
            throw "$($target.Name): $($_.Exception.Message)"
        }
    }
}

function Invoke-Flutter {
    param([string[]]$Arguments)

    if (-not (Test-Path -LiteralPath $FlutterExe)) {
        throw "Flutter executable not found at $FlutterExe. Set OFRIVO_FLUTTER_BIN to override it."
    }
    Push-Location $MobileRoot
    try {
        & $FlutterExe @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter command failed: $($Arguments -join ' ')"
        }
    } finally {
        Pop-Location
    }
}

function Invoke-Admin {
    $localEnv = Get-LocalSupabaseEnvironment
    $env:NEXT_PUBLIC_SUPABASE_URL = $localEnv.API_URL
    $env:NEXT_PUBLIC_SUPABASE_ANON_KEY = $localEnv.ANON_KEY
    Push-Location $AdminRoot
    try {
        & npm.cmd run dev
        if ($LASTEXITCODE -ne 0) {
            throw 'Admin dev server failed.'
        }
    } finally {
        Pop-Location
    }
}

function Invoke-LocalIntegration {
    $localEnv = Get-LocalSupabaseEnvironment
    $env:SUPABASE_LOCAL_API_URL = $localEnv.API_URL
    $env:SUPABASE_LOCAL_ANON_KEY = $localEnv.ANON_KEY
    $env:SUPABASE_LOCAL_SERVICE_ROLE_KEY = $localEnv.SERVICE_ROLE_KEY

    $runners = @(
        'supabase/tests/run_step11_local.mjs',
        'supabase/tests/run_version11_no_show_local.mjs',
        'supabase/tests/run_version11_expiry_local.mjs',
        'supabase/tests/run_version11_review_local.mjs',
        'supabase/tests/run_admin_local.mjs',
        'supabase/tests/run_provider_profile_local.mjs'
    )
    Push-Location $RepoRoot
    try {
        foreach ($runner in $runners) {
            & node $runner
            if ($LASTEXITCODE -ne 0) {
                throw "Local integration runner failed: $runner"
            }
        }
    } finally {
        Pop-Location
    }
    Write-Output 'Local Docker integration runners: PASS (step11, no-show, expiry, review, admin, provider-profile)'
}

function Invoke-AdbReverse {
    $adb = (Get-Command adb.exe -ErrorAction Stop).Source
    & $adb reverse tcp:54421 tcp:54421
    if ($LASTEXITCODE -ne 0) {
        throw 'adb reverse failed. Connect an authorized Android device first.'
    }
    & $adb reverse --list
}

function Get-MobileAppEnv {
    if (-not [string]::IsNullOrWhiteSpace($env:OFRIVO_APP_ENV)) {
        $appEnv = $env:OFRIVO_APP_ENV.Trim().ToLowerInvariant()
        if ($appEnv -notin @('development', 'staging', 'production')) {
            throw "Unsupported OFRIVO_APP_ENV '$appEnv'. Use development, staging, or production."
        }
        return $appEnv
    }
    return 'development'
}
function Get-MobileRuntimeConfig {
    param([Parameter(Mandatory = $true)][string]$DefaultUrl)

    $appEnv = Get-MobileAppEnv
    $hasUrl = -not [string]::IsNullOrWhiteSpace($env:OFRIVO_SUPABASE_URL)
    $hasAnonKey = -not [string]::IsNullOrWhiteSpace($env:OFRIVO_SUPABASE_ANON_KEY)
    if ($hasUrl -xor $hasAnonKey) {
        throw 'Set both OFRIVO_SUPABASE_URL and OFRIVO_SUPABASE_ANON_KEY, or clear both.'
    }
    if ($appEnv -in @('staging', 'production') -and -not ($hasUrl -and $hasAnonKey)) {
        throw "OFRIVO_APP_ENV=$appEnv requires OFRIVO_SUPABASE_URL and OFRIVO_SUPABASE_ANON_KEY."
    }

    if ($hasUrl -and $hasAnonKey) {
        return @{
            Url = $env:OFRIVO_SUPABASE_URL
            AnonKey = $env:OFRIVO_SUPABASE_ANON_KEY
        }
    }

    $localEnv = Get-LocalSupabaseEnvironment
    return @{
        Url = $DefaultUrl
        AnonKey = $localEnv.ANON_KEY
    }
}

function Invoke-MobileBuild {
    $appEnv = Get-MobileAppEnv
    $runtime = Get-MobileRuntimeConfig -DefaultUrl 'http://10.0.2.2:54421'
    Invoke-Flutter -Arguments @(
        'build',
        'apk',
        '--debug',
        '--no-pub',
        "--dart-define=SUPABASE_URL=$($runtime.Url)",
        "--dart-define=SUPABASE_ANON_KEY=$($runtime.AnonKey)",
        "--dart-define=APP_ENV=$appEnv"
    )
}
function Invoke-MobileRun {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [switch]$Reverse
    )

    if ($Reverse) {
        Invoke-AdbReverse
    }
    $appEnv = Get-MobileAppEnv
    $runtime = Get-MobileRuntimeConfig -DefaultUrl $Url
    $arguments = @(
        'run',
        '--debug',
        '--no-pub',
        "--dart-define=SUPABASE_URL=$($runtime.Url)",
        "--dart-define=SUPABASE_ANON_KEY=$($runtime.AnonKey)",
        "--dart-define=APP_ENV=$appEnv"
    )
    if ($env:OFRIVO_FLUTTER_DEVICE_ID) {
        $arguments += @('-d', $env:OFRIVO_FLUTTER_DEVICE_ID)
    }
    Invoke-Flutter -Arguments $arguments
}

switch ($Command) {
    'start' {
        $null = Invoke-Supabase -Arguments @('start')
        Write-LocalStatus
    }
    'status' {
        Write-LocalStatus
    }
    'reset' {
        $null = Invoke-Supabase -Arguments @('db', 'reset', '--yes')
        $null = Invoke-Supabase -Arguments @('db', 'lint')
        Write-Output 'Local Supabase reset and lint: PASS'
    }
    'lint' {
        $null = Invoke-Supabase -Arguments @('db', 'lint')
        Write-Output 'Local Supabase schema lint: PASS'
    }
    'health' {
        Invoke-LocalHealth
    }
    'integration' {
        Invoke-LocalIntegration
    }
    'adb-reverse' {
        Invoke-AdbReverse
    }
    'admin' {
        Invoke-Admin
    }
    'emulator' {
        Invoke-MobileRun -Url 'http://10.0.2.2:54421'
    }
    'device' {
        Invoke-MobileRun -Url 'http://127.0.0.1:54421' -Reverse
    }
    'apk' {
        Invoke-MobileBuild
    }
    'validate' {
        Push-Location $RepoRoot
        try {
            & node scripts/validate_version11.mjs
            & node supabase/tests/validate_provider_profile.mjs
            if ($LASTEXITCODE -ne 0) { throw 'Version 1.1 contract validation failed.' }
            Invoke-Flutter -Arguments @('analyze', '--no-pub')
            Invoke-Flutter -Arguments @('test', '--no-pub')
            Invoke-Flutter -Arguments @('build', 'apk', '--debug', '--no-pub')
        } finally {
            Pop-Location
        }
    }
}
