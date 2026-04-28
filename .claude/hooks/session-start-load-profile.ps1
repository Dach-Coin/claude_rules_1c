# SessionStart hook: deliver profile catalog manifest to Claude Code.
#
# - Reads .claude/profiles.json (committed map of profiles).
# - Reads .claude/profile.local.json (gitignored local choice; optional).
# - Emits hookSpecificOutput.additionalContext with full profile catalog
#   plus active-profile marker. The agent itself decides whether to
#   Read the listed files (idempotent on re-runs).
#
# Runs on each SessionStart matcher (startup|resume|clear|compact)
# with a single behaviour - the agent reconciles state from its context.
#
# UTF-8 without BOM is enforced for stdout/stderr (PS 5.1 default would
# add BOM and break the JSON contract). All file writes use .NET API to
# avoid the same BOM issue.

$ErrorActionPreference = 'Stop'

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding          = [System.Text.UTF8Encoding]::new($false)

# Repo root: prefer CLAUDE_PROJECT_DIR, fall back to current working directory.
$repoRoot = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { (Get-Location).Path }

$profilesPath = Join-Path $repoRoot '.claude/profiles.json'
$localPath    = Join-Path $repoRoot '.claude/profile.local.json'

function Emit-Empty {
    $payload = [ordered]@{
        hookSpecificOutput = [ordered]@{
            hookEventName     = 'SessionStart'
            additionalContext = ''
        }
    } | ConvertTo-Json -Depth 4 -Compress
    [Console]::Out.WriteLine($payload)
}

# 1. profiles.json
if (-not (Test-Path -LiteralPath $profilesPath)) {
    [Console]::Error.WriteLine("warning: profiles.json not found at $profilesPath")
    Emit-Empty
    return
}

try {
    $profilesText = [System.IO.File]::ReadAllText($profilesPath, [System.Text.UTF8Encoding]::new($false))
    $profilesJson = $profilesText | ConvertFrom-Json
} catch {
    [Console]::Error.WriteLine("warning: profiles.json invalid JSON: $($_.Exception.Message)")
    Emit-Empty
    return
}

if (-not $profilesJson.profiles) {
    [Console]::Error.WriteLine('warning: profiles.json has no .profiles key')
    Emit-Empty
    return
}

# 2. profile.local.json (optional)
$active = $null
if (Test-Path -LiteralPath $localPath) {
    try {
        $localText = [System.IO.File]::ReadAllText($localPath, [System.Text.UTF8Encoding]::new($false))
        $localJson = $localText | ConvertFrom-Json
        if ($localJson -and $localJson.PSObject.Properties.Name -contains 'active') {
            $candidate = $localJson.active
            if ($candidate -and ($candidate -is [string])) {
                if ($profilesJson.profiles.PSObject.Properties.Name -contains $candidate) {
                    $active = $candidate
                } else {
                    [Console]::Error.WriteLine("warning: active profile '$candidate' not in profiles.json")
                }
            }
        }
    } catch {
        [Console]::Error.WriteLine("warning: profile.local.json invalid JSON: $($_.Exception.Message)")
    }
}

# 3. Build full catalog manifest
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('### Profile catalog')
$lines.Add('')
$lines.Add('Available profiles (defined in .claude/profiles.json):')
$lines.Add('')
foreach ($prop in $profilesJson.profiles.PSObject.Properties) {
    $name = $prop.Name
    $entry = $prop.Value
    $desc = if ($entry._description) { [string]$entry._description } else { '' }
    $files = if ($entry.files) { @($entry.files) } else { @() }
    $lines.Add("- **$name** - $desc")
    if ($files.Count -gt 0) {
        $lines.Add('  Files: ' + ($files -join ', '))
    } else {
        $lines.Add('  Files: (none)')
    }
}
$lines.Add('')
if ($active) {
    $activeFiles = if ($profilesJson.profiles.$active.files) { @($profilesJson.profiles.$active.files) } else { @() }
    $lines.Add("### Active profile: $active")
    $lines.Add('')
    $lines.Add("Files to read now (Read these before answering the user's first prompt):")
    $lines.Add('')
    if ($activeFiles.Count -gt 0) {
        foreach ($f in $activeFiles) { $lines.Add("- $f") }
    } else {
        $lines.Add('- (active profile has no files)')
    }
    $lines.Add('')
    $lines.Add('If a path is missing in the working tree, skip it and report which paths were skipped. If your conversation history already shows these files Read earlier (and they have not been compacted away), no re-Read is needed - Read is idempotent but uses tokens.')
} else {
    $lines.Add('### Active profile: none')
    $lines.Add('')
    $lines.Add('No files to read automatically. Use the catalog above to propose 1-3 ranked profiles (see .claude/rules/user_rules.md for the proposal flow and ranking heuristics), then wait for the user to confirm before Reading any files.')
}

$manifestText = $lines -join "`n"

# 4. Compact-fallback if catalog grows past safety threshold (<10000 char limit).
if ($manifestText.Length -gt 9000) {
    $names = @($profilesJson.profiles.PSObject.Properties.Name) -join ', '
    if ($active) {
        $action = "Active profile is set ($active). Read .claude/profiles.json to get the file list for profile '$active', then Read those files before answering the user's first prompt."
        $head = "### Active profile: $active"
    } else {
        $action = 'No active profile. Read .claude/profiles.json to get full descriptions, then propose 1-3 ranked profiles (see .claude/rules/user_rules.md for the proposal flow and ranking heuristics) and wait for the user to confirm before Reading any files.'
        $head = '### Active profile: none'
    }
    $manifestText = "### Profile catalog (compact)`n`nAvailable profiles: $names`n`n$head`n`n$action"
    [Console]::Error.WriteLine('warning: full catalog exceeds 9000 chars, falling back to compact form')
}

# 5. Emit JSON via .NET writer (avoids any PS 5.1 stream-encoding surprises).
$payload = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName     = 'SessionStart'
        additionalContext = $manifestText
    }
} | ConvertTo-Json -Depth 4 -Compress

[Console]::Out.WriteLine($payload)
