# Installs paginel-text (Paginel Text - CLI) on Windows 10 and 11 (x64) from the releases of
# https://github.com/paginel/paginel-cli, in PowerShell (Windows PowerShell 5.1 or PowerShell 7):
#
#   irm https://raw.githubusercontent.com/paginel/paginel-cli/main/install.ps1 | iex
#
# What it does: picks the Windows archive in SHA256SUMS.txt of the release, downloads it, checks its SHA-256, installs
# paginel-text.exe in %LOCALAPPDATA%\Programs\paginel-text (or PAGINEL_CLI_DEST), adds that folder to your user PATH,
# runs `paginel-text --version`. No administrator rights; nothing else is written. Run it again to update.
# Uninstall: delete that folder and remove it from your user PATH (Settings > System > About > Advanced system settings
# > Environment Variables).
#
# Environment (set before the line, for example $env:PAGINEL_CLI_VERSION = "0.3.0"):
#   PAGINEL_CLI_DEST      the folder to install into (default: %LOCALAPPDATA%\Programs\paginel-text)
#   PAGINEL_CLI_VERSION   a version such as 0.3.0 (default: the latest release); pin it in scripts and CI
#   PAGINEL_CLI_NO_PATH   1: do not change the user PATH
#   PAGINEL_CLI_REPO      the GitHub repository (default: paginel/paginel-cli)
#
# Linux: install.sh   curl -fsSL https://raw.githubusercontent.com/paginel/paginel-cli/main/install.sh | sh
#
# Everything runs inside one script block, so that the settings below stay out of your session, and nothing calls
# `exit` (it would close your window when run through iex): an error stops the script with a message.

& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'   # the progress bar makes downloads very slow in PowerShell 5.1
    # Windows PowerShell 5.1 may not offer TLS 1.2 by default; GitHub needs it.
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $repo = if ($env:PAGINEL_CLI_REPO) { $env:PAGINEL_CLI_REPO } else { 'paginel/paginel-cli' }
    $dest = if ($env:PAGINEL_CLI_DEST) { $env:PAGINEL_CLI_DEST } else { Join-Path $env:LOCALAPPDATA 'Programs\paginel-text' }
    if ($env:PAGINEL_CLI_VERSION) {
        $base = "https://github.com/$repo/releases/download/v$($env:PAGINEL_CLI_VERSION.TrimStart('v'))"
    } else {
        $base = "https://github.com/$repo/releases/latest/download"
    }
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw 'paginel-text install: paginel-text is built for 64-bit Windows only.'
    }

    $work = Join-Path ([IO.Path]::GetTempPath()) ('paginel-text-' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work | Out-Null
    try {
        Write-Host "==> Release: $base"
        $sums = Join-Path $work 'SHA256SUMS.txt'
        try { Invoke-WebRequest -UseBasicParsing -Uri "$base/SHA256SUMS.txt" -OutFile $sums }
        catch { throw "paginel-text install: cannot download $base/SHA256SUMS.txt ($($_.Exception.Message))" }

        # The archive's name carries the version: read it from the list of checksums.
        $line = Get-Content $sums | Where-Object { $_ -match '^[0-9a-fA-F]{64}\s+\*?paginel-text-\S+-x86_64-pc-windows-msvc\.zip$' } |
            Select-Object -First 1
        if (-not $line) { throw 'paginel-text install: no Windows archive in this release.' }
        $parts = $line -split '\s+'
        $expected = $parts[0].ToLowerInvariant()
        $file = $parts[1].TrimStart('*')
        $stem = $file -replace '\.zip$', ''

        Write-Host "==> Downloading $file"
        $zip = Join-Path $work $file
        try { Invoke-WebRequest -UseBasicParsing -Uri "$base/$file" -OutFile $zip }
        catch { throw "paginel-text install: cannot download $base/$file ($($_.Exception.Message))" }
        $got = (Get-FileHash -Path $zip -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($got -ne $expected) {
            throw "paginel-text install: $file has SHA-256 $got, SHA256SUMS.txt says $expected. Nothing was installed."
        }
        Write-Host '==> SHA-256 checked'

        Expand-Archive -Path $zip -DestinationPath $work -Force
        $exe = Join-Path $work "$stem\paginel-text.exe"
        if (-not (Test-Path $exe)) { throw "paginel-text install: $file does not contain $stem\paginel-text.exe." }

        New-Item -ItemType Directory -Force -Path $dest | Out-Null
        $target = Join-Path $dest 'paginel-text.exe'
        try { Copy-Item -Path $exe -Destination $target -Force }
        catch { throw "paginel-text install: cannot write $target (is paginel-text running?) ($($_.Exception.Message))" }
        # Downloaded through PowerShell, the file has no mark of the web; remove one anyway (SmartScreen).
        Unblock-File -Path $target -ErrorAction SilentlyContinue
        $installed = & $target --version 2>&1
        if ($LASTEXITCODE -ne 0) { throw "paginel-text install: $target does not run: $installed" }
        Write-Host "==> Installed: $target ($installed)"

        # The user PATH, read and written raw in the registry so that entries such as %USERPROFILE%\... stay as they are.
        $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
        $raw = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $entries = @($raw -split ';' | Where-Object { $_ -ne '' })
        $already = $entries | Where-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') -ieq $dest.TrimEnd('\') }
        if ($already) {
            Write-Host "==> $dest is already on your user PATH"
        } elseif ($env:PAGINEL_CLI_NO_PATH -eq '1') {
            Write-Host "PAGINEL_CLI_NO_PATH=1: your PATH is unchanged; add $dest to it to call paginel-text from anywhere."
        } else {
            $key.SetValue('Path', (($entries + $dest) -join ';'), [Microsoft.Win32.RegistryValueKind]::ExpandString)
            # Tell Windows that the environment changed (new terminals then see the PATH): setting a user variable
            # through .NET broadcasts the change; this one is removed at once.
            [Environment]::SetEnvironmentVariable('PAGINEL_CLI_INSTALL', '1', 'User')
            [Environment]::SetEnvironmentVariable('PAGINEL_CLI_INSTALL', $null, 'User')
            $env:Path = "$env:Path;$dest"
            Write-Host "==> $dest added to your user PATH (open a new terminal elsewhere)"
        }
        $key.Close()

        Write-Host ''
        Write-Host 'Next: paginel-text --help'
        Write-Host "Docs and examples: https://github.com/$repo"
        Write-Host "Licence: free to use, proprietary (LICENSE in the archive, or https://github.com/$repo/blob/main/LICENSE)."
    } finally {
        Remove-Item -Recurse -Force -Path $work -ErrorAction SilentlyContinue
    }
}
