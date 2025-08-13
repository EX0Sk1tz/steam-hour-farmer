Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

### ---- USER SETTINGS ----
$envPath = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) ".env"

function Load-EnvVars {
    param($path)
    $vars = @{}
    if (Test-Path $path) {
        Get-Content $path | ForEach-Object {
            if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
            if ($_ -match '^\s*([^=]+)\s*=\s*"(.*)"\s*$') {
                $vars[$matches[1].Trim()] = $matches[2]
            }
        }
    }
    return $vars
}

$envVars = Load-EnvVars $envPath

$SteamApiKey = $envVars['STEAM_API_KEY']
$SteamId64   = $envVars['STEAM_ID64']
$FarmerDir = Split-Path -Parent $MyInvocation.MyCommand.Path

### ------------------------

function Get-OwnedGames {
    param($Key,$SteamId)
    $url = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=$Key&steamid=$SteamId&include_appinfo=1&include_played_free_games=1"
    try { (Invoke-RestMethod -Uri $url -Method GET -TimeoutSec 30).response.games | Sort-Object -Property name }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to load games: $($_.Exception.Message)","Error","OK","Error") | Out-Null
        @()
    }
}

function Load-EnvFile {
    param($envPath)
    $env = @{}
    if (Test-Path $envPath) {
        Get-Content $envPath | ForEach-Object {
            if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
            if ($_ -match '^\s*([^=]+)\s*=\s*"(.*)"\s*$') {
                $env[$matches[1].Trim()] = $matches[2]
            }
        }
    }
    return $env
}

function Save-EnvFile {
    param($envPath,$envObj)
    $lines = @()
    foreach ($k in $envObj.Keys) {
        $lines += "$k=""$($envObj[$k])"""
    }
    Set-Content -Path $envPath -Value $lines -Encoding UTF8
}

function Start-Farmer {
    param($workDir)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.WorkingDirectory = $workDir
    $psi.UseShellExecute  = $true
    if (Get-Command "steam-hour-farmer" -ErrorAction SilentlyContinue) {
        $psi.FileName="cmd.exe"; $psi.Arguments="/c steam-hour-farmer"
    } else {
        $psi.FileName="cmd.exe"; $psi.Arguments="/c npx steam-hour-farmer"
    }
    [System.Diagnostics.Process]::Start($psi) | Out-Null
}

# === UI ===
$form = New-Object System.Windows.Forms.Form
$form.Text = "Steam Hour Farmer - Game Picker"
$form.Size = New-Object System.Drawing.Size(820,620)
$form.StartPosition = "CenterScreen"

$lblSearch = New-Object System.Windows.Forms.Label
$lblSearch.Text="Search:"
$lblSearch.Location=New-Object System.Drawing.Point(10,15)
$lblSearch.AutoSize=$true
$form.Controls.Add($lblSearch)

$txtSearch = New-Object System.Windows.Forms.TextBox
$txtSearch.Location=New-Object System.Drawing.Point(65,10)
$txtSearch.Size=New-Object System.Drawing.Size(620,25)
$txtSearch.Anchor = 'Top,Left,Right'
$form.Controls.Add($txtSearch)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text="Reload games"
$btnRefresh.Location=New-Object System.Drawing.Point(695,8)
$btnRefresh.Size=New-Object System.Drawing.Size(95,28)
$btnRefresh.Anchor = 'Top,Right'
$form.Controls.Add($btnRefresh)

$clb = New-Object System.Windows.Forms.CheckedListBox
$clb.Location=New-Object System.Drawing.Point(10,45)
$clb.Size=New-Object System.Drawing.Size(780,460)
$clb.CheckOnClick=$true
$clb.Sorted=$false
$clb.Anchor = 'Top,Bottom,Left,Right'
$form.Controls.Add($clb)

$btnAll = New-Object System.Windows.Forms.Button
$btnAll.Text="Select all (filtered)"
$btnAll.Location=New-Object System.Drawing.Point(10,515)
$btnAll.Size=New-Object System.Drawing.Size(140,30)
$btnAll.Anchor = 'Bottom,Left'
$form.Controls.Add($btnAll)

$btnNone = New-Object System.Windows.Forms.Button
$btnNone.Text="Clear"
$btnNone.Location=New-Object System.Drawing.Point(160,515)
$btnNone.Size=New-Object System.Drawing.Size(80,30)
$btnNone.Anchor = 'Bottom,Left'
$form.Controls.Add($btnNone)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text="Start farmer with selection"
$btnStart.Size=New-Object System.Drawing.Size(180,30)
$btnStart.Location=New-Object System.Drawing.Point(610,515)   # bottom-right
$btnStart.Anchor = 'Bottom,Right'
$form.Controls.Add($btnStart)

# Data
$script:allGames=@()
function Populate-List([string]$filter) {
    $clb.Items.Clear()
    $toShow = if ([string]::IsNullOrWhiteSpace($filter)) { $script:allGames } else { $script:allGames | Where-Object { $_.name -like "*$filter*" } }
    foreach ($g in $toShow) { [void]$clb.Items.Add("$($g.name)  (AppID: $($g.appid))") }
}

$btnRefresh.Add_Click({
    if (-not $SteamApiKey -or -not $SteamId64) {
        [System.Windows.Forms.MessageBox]::Show("Set SteamApiKey and SteamId64 at the top of the script.","Missing config") | Out-Null
        return
    }
    $form.Cursor="WaitCursor"
    $script:allGames = Get-OwnedGames -Key $SteamApiKey -SteamId $SteamId64
    $form.Cursor="Default"
    Populate-List $txtSearch.Text
})

$txtSearch.Add_TextChanged({ Populate-List $txtSearch.Text })
$btnAll.Add_Click({ for ($i=0; $i -lt $clb.Items.Count; $i++) { $clb.SetItemChecked($i,$true) } })
$btnNone.Add_Click({ for ($i=0; $i -lt $clb.Items.Count; $i++) { $clb.SetItemChecked($i,$false) } })

$btnStart.Add_Click({
    $envPath = Join-Path $FarmerDir ".env"
    if (-not (Test-Path $envPath)) { [System.Windows.Forms.MessageBox]::Show("Missing .env in:`n$FarmerDir","Error") | Out-Null; return }
    $envObj = Load-EnvFile $envPath
    if ([string]::IsNullOrWhiteSpace($envObj.ACCOUNT_NAME) -or [string]::IsNullOrWhiteSpace($envObj.PASSWORD)) {
        [System.Windows.Forms.MessageBox]::Show("Your .env must contain ACCOUNT_NAME and PASSWORD.","Error") | Out-Null; return
    }

    $selectedAppIds=@()
    foreach ($item in $clb.CheckedItems) {
        if ($item -match 'AppID:\s*(\d+)') { $selectedAppIds += $matches[1] }
    }
    if ($selectedAppIds.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Select at least one game.","Nothing selected") | Out-Null; return
    }

    $gamesValue = ($selectedAppIds -join ",")
    Copy-Item $envPath "$envPath.bak" -Force
    $envObj.GAMES = $gamesValue
    Save-EnvFile $envPath $envObj

    Start-Farmer -workDir $FarmerDir
    [System.Windows.Forms.MessageBox]::Show("Started farmer with GAMES=`"$gamesValue`".`nBackup saved as .env.bak","Launched") | Out-Null
})

# Auto-load on open
$form.Add_Shown({ $btnRefresh.PerformClick() })

[void]$form.ShowDialog()
