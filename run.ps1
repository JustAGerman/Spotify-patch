param
(

    [Parameter(HelpMessage = "Change recommended version of Spotify.")]
    [Alias("v")]
    [string]$version,

    [Parameter(HelpMessage = "Use github.io mirror instead of raw.githubusercontent.")]
    [Alias("m")]
    [switch]$mirror,

    [Parameter(HelpMessage = "Developer mode activation.")]
    [Alias("dev")]
    [switch]$devtools,

    [Parameter(HelpMessage = 'Disable podcasts/episodes/audiobooks from homepage.')]
    [switch]$podcasts_off,

    [Parameter(HelpMessage = 'Disable Ad-like sections from homepage')]
    [switch]$adsections_off,

    [Parameter(HelpMessage = 'Disable canvas from homepage')]
    [switch]$canvashome_off,
    
    [Parameter(HelpMessage = 'Do not disable podcasts/episodes/audiobooks from homepage.')]
    [switch]$podcasts_on,
    
    [Parameter(HelpMessage = 'Block Spotify automatic updates.')]
    [switch]$block_update_on,
    
    [Parameter(HelpMessage = 'Do not block Spotify automatic updates.')]
    [switch]$block_update_off,
    
    [Parameter(HelpMessage = 'Change limit for clearing audio cache.')]
    [Alias('cl')]
    [int]$cache_limit,
    
    [Parameter(HelpMessage = 'Automatic uninstallation of Spotify MS if it was found.')]
    [switch]$confirm_uninstall_ms_spoti,
    
    [Parameter(HelpMessage = 'Overwrite outdated or unsupported version of Spotify with the recommended version.')]
    [Alias('sp-over')]
    [switch]$confirm_spoti_recomended_over,
    
    [Parameter(HelpMessage = 'Uninstall outdated or unsupported version of Spotify and install the recommended version.')]
    [Alias('sp-uninstall')]
    [switch]$confirm_spoti_recomended_uninstall,
    
    [Parameter(HelpMessage = 'Installation without ad blocking for premium accounts.')]
    [switch]$premium,

    [Parameter(HelpMessage = 'Disable Spotify autostart on Windows boot.')]
    [switch]$DisableStartup,
    
    [Parameter(HelpMessage = 'Automatic launch of Spotify after installation is complete.')]
    [switch]$start_spoti,
    
    [Parameter(HelpMessage = 'Experimental features operated by Spotify.')]
    [switch]$exp_spotify,

    [Parameter(HelpMessage = 'Enable top search bar.')]
    [switch]$topsearchbar,

    [Parameter(HelpMessage = 'Enable new fullscreen mode (Experimental)')]
    [switch]$newFullscreenMode,

    [Parameter(HelpMessage = 'disable subfeed filter chips on home.')]
    [switch]$homesub_off,
    
    [Parameter(HelpMessage = 'Do not hide the icon of collaborations in playlists.')]
    [switch]$hide_col_icon_off,
    
    [Parameter(HelpMessage = 'Disable new right sidebar.')]
    [switch]$rightsidebar_off,

    [Parameter(HelpMessage = 'it`s killing the heart icon, you`re able to save and choose the destination for any song, playlist, or podcast')]
    [switch]$plus,

    [Parameter(HelpMessage = 'Enable funny progress bar.')]
    [switch]$funnyprogressBar,

    [Parameter(HelpMessage = 'New theme activated (new right and left sidebar, some cover change)')]
    [switch]$new_theme,

    [Parameter(HelpMessage = 'Enable right sidebar coloring to match cover color)')]
    [switch]$rightsidebarcolor,
    
    [Parameter(HelpMessage = 'Returns old lyrics')]
    [switch]$old_lyrics,

    [Parameter(HelpMessage = 'Disable native lyrics')]
    [switch]$lyrics_block,

    [Parameter(HelpMessage = 'Do not create desktop shortcut.')]
    [switch]$no_shortcut,

    [Parameter(HelpMessage = 'Static color for lyrics.')]
    [ArgumentCompleter({ param($cmd, $param, $wordToComplete)
            [array] $validValues = @('blue', 'blueberry', 'discord', 'drot', 'default', 'forest', 'fresh', 'github', 'lavender', 'orange', 'postlight', 'pumpkin', 'purple', 'radium', 'relish', 'red', 'sandbar', 'spotify', 'spotify#2', 'strawberry', 'turquoise', 'yellow', 'zing', 'pinkle', 'krux', 'royal', 'oceano')
            $validValues -like "*$wordToComplete*"
        })]
    [string]$lyrics_stat,
)

# Ignore errors from `Stop-Process`
$PSDefaultParameterValues['Stop-Process:ErrorAction'] = [System.Management.Automation.ActionPreference]::SilentlyContinue

function Format-LanguageCode {
    return 'en'
}

$spotifyDirectory = Join-Path $env:APPDATA 'Spotify'
$spotifyDirectory2 = Join-Path $env:LOCALAPPDATA 'Spotify'
$spotifyExecutable = Join-Path $spotifyDirectory 'Spotify.exe'
$exe_bak = Join-Path $spotifyDirectory 'Spotify.bak'
$spotifyUninstall = Join-Path ([System.IO.Path]::GetTempPath()) 'SpotifyUninstall.exe'
$start_menu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Spotify.lnk'

$upgrade_client = $false

# Check version Powershell
$psv = $PSVersionTable.PSVersion.major
if ($psv -ge 7) {
    Import-Module Appx -UseWindowsPowerShell -WarningAction:SilentlyContinue
}

# add Tls12
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12;

function Get-Link {
    param (
        [Alias("e")]
        [string]$endlink
    )
    return "https://raw.githubusercontent.com/JustAGerman/Spotify-patch/refs/heads/main" + $endlink
}

function CallLang($clg) {

    $ProgressPreference = 'SilentlyContinue'
    
    try {
        $response = (iwr -Uri (Get-Link -e "/en.ps1") -UseBasicParsing).Content
        if ($mirror) { $response = [System.Text.Encoding]::UTF8.GetString($response) }
        Invoke-Expression $response
    }
    catch {
        Write-Host "Error loading $clg language"
        Pause
        Exit
    }
}

# Set language code for script.
$langCode = Format-LanguageCode -LanguageCode $Language

$lang = CallLang -clg $langCode

Write-Host ($lang).Welcome
Write-Host

# Check version Windows
$os = Get-CimInstance -ClassName "Win32_OperatingSystem" -ErrorAction SilentlyContinue
if ($os) {
    $osCaption = $os.Caption
}
else {
    $osCaption = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ProductName).ProductName
}
$pattern = "\bWindows (7|8(\.1)?|10|11|12)\b"
$reg = [regex]::Matches($osCaption, $pattern)
$win_os = $reg.Value

$win12 = $win_os -match "\windows 12\b"
$win11 = $win_os -match "\windows 11\b"
$win10 = $win_os -match "\windows 10\b"
$win8_1 = $win_os -match "\windows 8.1\b"
$win8 = $win_os -match "\windows 8\b"
$win7 = $win_os -match "\windows 7\b"

$match_v = "^\d+\.\d+\.\d+\.\d+\.g[0-9a-f]{8}-\d+$"
if ($version) {
    if ($version -match $match_v) {
        $onlineFull = $version
    }
    else {      
        Write-Warning "Invalid $($version) format. Example: 1.2.13.661.ga588f749-4064"
        Write-Host
    }
}

$old_os = $win7 -or $win8 -or $win8_1

# latest tested version for Win 7-8.1 
$last_win7_full = "1.2.5.1006.g22820f93-1078"

if (!($version -and $version -match $match_v)) {
    if ($old_os) { 
        $onlineFull = $last_win7_full
    }
    else {  
        # latest tested version for Win 10-12 
        $onlineFull = "1.2.66.447.g4e37e896-540"
    }
}
else {
    if ($old_os) {
        $last_win7 = "1.2.5.1006"
        if ([version]($onlineFull -split ".g")[0] -gt [version]$last_win7) { 

            Write-Warning ("Version {0} is only supported on Windows 10 and above" -f ($onlineFull -split ".g")[0])   
            Write-Warning ("The recommended version has been automatically changed to {0}, the latest supported version for Windows 7-8.1" -f $last_win7)
            Write-Host
            $onlineFull = $last_win7_full
        }
    }
}
$online = ($onlineFull -split ".g")[0]


function Get {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        [int]$MaxRetries = 3,
        [int]$RetrySeconds = 3,
        [string]$OutputPath
    )

    $params = @{
        Uri        = $Url
        TimeoutSec = 15
    }

    if ($OutputPath) {
        $params['OutFile'] = $OutputPath
    }

    for ($i = 0; $i -lt $MaxRetries; $i++) {
        try {
            $response = Invoke-RestMethod @params
            return $response
        }
        catch {
            Write-Warning "Attempt $($i+1) of $MaxRetries failed: $_"
            if ($i -lt $MaxRetries - 1) {
                Start-Sleep -Seconds $RetrySeconds
            }
        }
    }

    Write-Host
    Write-Host "ERROR: " -ForegroundColor Red -NoNewline; Write-Host "Failed to retrieve data from $Url" -ForegroundColor White
    Write-Host
    return $null
}


function incorrectValue {

    Write-Host ($lang).Incorrect"" -ForegroundColor Red -NoNewline
    Write-Host ($lang).Incorrect2"" -NoNewline
    Start-Sleep -Milliseconds 1000
    Write-Host "3" -NoNewline 
    Start-Sleep -Milliseconds 1000
    Write-Host " 2" -NoNewline
    Start-Sleep -Milliseconds 1000
    Write-Host " 1"
    Start-Sleep -Milliseconds 1000     
    Clear-Host
} 

function Unlock-Folder {
    $blockFileUpdate = Join-Path $env:LOCALAPPDATA 'Spotify\Update'

    if (Test-Path $blockFileUpdate -PathType Container) {
        $folderUpdateAccess = Get-Acl $blockFileUpdate
        $hasDenyAccessRule = $false
        
        foreach ($accessRule in $folderUpdateAccess.Access) {
            if ($accessRule.AccessControlType -eq 'Deny') {
                $hasDenyAccessRule = $true
                $folderUpdateAccess.RemoveAccessRule($accessRule)
            }
        }
        
        if ($hasDenyAccessRule) {
            Set-Acl $blockFileUpdate $folderUpdateAccess
        }
    }
}
function Mod-F {
    param(
        [string] $template,
        [object[]] $arguments
    )
    
    $result = $template
    for ($i = 0; $i -lt $arguments.Length; $i++) {
        $placeholder = "{${i}}"
        $value = $arguments[$i]
        $result = $result -replace [regex]::Escape($placeholder), $value
    }
    
    return $result
}

function downloadSp() {

    $webClient = New-Object -TypeName System.Net.WebClient

    Import-Module BitsTransfer
        
    $max_x86 = [Version]"1.2.53"
    $versionParts = $onlineFull -split '\.'
    $short = [Version]"$($versionParts[0]).$($versionParts[1]).$($versionParts[2])"
    $arch = if ($short -le $max_x86) { "win32-x86" } else { "win32-x86_64" }

    $web_Url = "https://download.scdn.co/upgrade/client/$arch/spotify_installer-$onlineFull.exe"
    $local_Url = "$PWD\SpotifySetup.exe" 
    $web_name_file = "SpotifySetup.exe"

    try { if (curl.exe -V) { $curl_check = $true } }
    catch { $curl_check = $false }
    
    try { 
        if ($curl_check) {
            $stcode = curl.exe -Is -w "%{http_code} \n" -o /dev/null -k $web_Url --retry 2 --ssl-no-revoke
            if ($stcode.trim() -ne "200") {
                Write-Host "Curl error code: $stcode"; throw
            }
            curl.exe -q -k $web_Url -o $local_Url --progress-bar --retry 3 --ssl-no-revoke
            return
        }
        if (!($curl_check ) -and $null -ne (Get-Module -Name BitsTransfer -ListAvailable)) {
            $ProgressPreference = 'Continue'
            Start-BitsTransfer -Source  $web_Url -Destination $local_Url  -DisplayName ($lang).Download5 -Description "$online "
            return
        }
        if (!($curl_check ) -and $null -eq (Get-Module -Name BitsTransfer -ListAvailable)) {
            $webClient.DownloadFile($web_Url, $local_Url) 
            return
        }
    }

    catch {
        Write-Host
        Write-Host ($lang).Download $web_name_file -ForegroundColor RED
        $Error[0].Exception
        Write-Host
        Write-Host ($lang).Download2`n
        Start-Sleep -Milliseconds 5000 
        try { 

            if ($curl_check) {
                $stcode = curl.exe -Is -w "%{http_code} \n" -o /dev/null -k $web_Url --retry 2 --ssl-no-revoke
                if ($stcode.trim() -ne "200") {
                    Write-Host "Curl error code: $stcode"; throw
                }
                curl.exe -q -k $web_Url -o $local_Url --progress-bar --retry 3 --ssl-no-revoke
                return
            }
            if (!($curl_check ) -and $null -ne (Get-Module -Name BitsTransfer -ListAvailable) -and !($curl_check )) {
                Start-BitsTransfer -Source  $web_Url -Destination $local_Url  -DisplayName ($lang).Download5 -Description "$online "
                return
            }
            if (!($curl_check ) -and $null -eq (Get-Module -Name BitsTransfer -ListAvailable) -and !($curl_check )) {
                $webClient.DownloadFile($web_Url, $local_Url) 
                return
            }
        }
        
        catch {
            Write-Host ($lang).Download3 -ForegroundColor RED
            $Error[0].Exception
            Write-Host
            Write-Host ($lang).Download4`n
            ($lang).StopScript
            $tempDirectory = $PWD
            Pop-Location
            Start-Sleep -Milliseconds 200
            Remove-Item -Recurse -LiteralPath $tempDirectory
            Pause
            Exit
        }
    }
} 

function DesktopFolder {

    # If the default Dekstop folder does not exist, then try to find it through the registry.
    $ErrorActionPreference = 'SilentlyContinue' 
    if (Test-Path "$env:USERPROFILE\Desktop") {  
        $desktop_folder = "$env:USERPROFILE\Desktop"  
    }

    $regedit_desktop_folder = Get-ItemProperty -Path "Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders\"
    $regedit_desktop = $regedit_desktop_folder.'{754AC886-DF64-4CBA-86B5-F7FBF4FBCEF5}'
 
    if (!(Test-Path "$env:USERPROFILE\Desktop")) {
        $desktop_folder = $regedit_desktop
    }
    return $desktop_folder
}

function Kill-Spotify {
    param (
        [int]$maxAttempts = 5
    )

    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        $allProcesses = Get-Process -ErrorAction SilentlyContinue

        $spotifyProcesses = $allProcesses | Where-Object { $_.ProcessName -like "*spotify*" }

        if ($spotifyProcesses) {
            foreach ($process in $spotifyProcesses) {
                try {
                    Stop-Process -Id $process.Id -Force
                }
                catch {
                    # Ignore NoSuchProcess exception
                }
            }
            Start-Sleep -Seconds 1
        }
        else {
            break
        }
    }

    if ($attempt -gt $maxAttempts) {
        Write-Host "The maximum number of attempts to terminate a process has been reached."
    }
}


Kill-Spotify

# Remove Spotify Windows Store If Any
if ($win10 -or $win11 -or $win8_1 -or $win8 -or $win12) {

    if (Get-AppxPackage -Name SpotifyAB.SpotifyMusic) {
        Write-Host ($lang).MsSpoti`n
        
        if (!($confirm_uninstall_ms_spoti)) {
            do {
                $ch = Read-Host -Prompt ($lang).MsSpoti2
                Write-Host
                if (!($ch -eq 'n' -or $ch -eq 'y')) {
                    incorrectValue
                }
            }
    
            while ($ch -notmatch '^y$|^n$')
        }
        if ($confirm_uninstall_ms_spoti) { $ch = 'y' }
        if ($ch -eq 'y') {      
            $ProgressPreference = 'SilentlyContinue' # Hiding Progress Bars
            if ($confirm_uninstall_ms_spoti) { Write-Host ($lang).MsSpoti3`n }
            if (!($confirm_uninstall_ms_spoti)) { Write-Host ($lang).MsSpoti4`n }
            Get-AppxPackage -Name SpotifyAB.SpotifyMusic | Remove-AppxPackage
        }
        if ($ch -eq 'n') {
            Read-Host ($lang).StopScript 
            Pause
            Exit
        }
    }
}

# Attempt to fix the hosts file
$hostsFilePath = Join-Path $Env:windir 'System32\Drivers\Etc\hosts'
$hostsBackupFilePath = Join-Path $Env:windir 'System32\Drivers\Etc\hosts.bak'

if (Test-Path -Path $hostsFilePath) {

    $hosts = [System.IO.File]::ReadAllLines($hostsFilePath)
    $regex = "^(?!#|\|)((?:.*?(?:download|upgrade)\.scdn\.co|.*?spotify).*)"

    if ($hosts -match $regex) {

        Write-Host ($lang).HostInfo`n
        Write-Host ($lang).HostBak`n

        Copy-Item -Path $hostsFilePath -Destination $hostsBackupFilePath -ErrorAction SilentlyContinue

        if ($?) {

            Write-Host ($lang).HostDel

            try {
                $hosts = $hosts | Where-Object { $_ -notmatch $regex }
                [System.IO.File]::WriteAllLines($hostsFilePath, $hosts)
            }
            catch {
                Write-Host ($lang).HostError`n -ForegroundColor Red
                $copyError = $Error[0]
                Write-Host "Error: $($copyError.Exception.Message)`n" -ForegroundColor Red
            }
        }
        else {
            Write-Host ($lang).HostError`n -ForegroundColor Red
            $copyError = $Error[0]
            Write-Host "Error: $($copyError.Exception.Message)`n" -ForegroundColor Red
        }
    }
}

# Unique directory name based on time
Push-Location -LiteralPath ([System.IO.Path]::GetTempPath())
New-Item -Type Directory -Name "SpotX_Temp-$(Get-Date -UFormat '%Y-%m-%d_%H-%M-%S')" | Convert-Path | Set-Location

if ($premium) {
    Write-Host ($lang).Prem`n
}

$spotifyInstalled = (Test-Path -LiteralPath $spotifyExecutable)

if ($spotifyInstalled) {
    
    # Check version Spotify offline
    $offline = (Get-Item $spotifyExecutable).VersionInfo.FileVersion
 
    # Version comparison
    # converting strings to arrays of numbers using the -split operator and a foreach loop
    
    $arr1 = $online -split '\.' | foreach { [int]$_ }
    $arr2 = $offline -split '\.' | foreach { [int]$_ }

    # compare each element of the array in order from most significant to least significant.
    for ($i = 0; $i -lt $arr1.Length; $i++) {
        if ($arr1[$i] -gt $arr2[$i]) {
            $oldversion = $true
            break
        }
        elseif ($arr1[$i] -lt $arr2[$i]) {
            $testversion = $true
            break
        }
    }

    # Old version Spotify
    if ($oldversion) {
        if ($confirm_spoti_recomended_over -or $confirm_spoti_recomended_uninstall) {
            Write-Host ($lang).OldV`n
        }
        if (!($confirm_spoti_recomended_over) -and !($confirm_spoti_recomended_uninstall)) {
            do {
                Write-Host (($lang).OldV2 -f $offline, $online)
                $ch = Read-Host -Prompt ($lang).OldV3
                Write-Host
                if (!($ch -eq 'n' -or $ch -eq 'y')) {
                    incorrectValue
                }
            }
            while ($ch -notmatch '^y$|^n$')
        }
        if ($confirm_spoti_recomended_over -or $confirm_spoti_recomended_uninstall) { 
            $ch = 'y' 
            Write-Host ($lang).AutoUpd`n
        }
        if ($ch -eq 'y') { 
            $upgrade_client = $true 

            if (!($confirm_spoti_recomended_over) -and !($confirm_spoti_recomended_uninstall)) {
                do {
                    $ch = Read-Host -Prompt (($lang).DelOrOver -f $offline)
                    Write-Host
                    if (!($ch -eq 'n' -or $ch -eq 'y')) {
                        incorrectValue
                    }
                }
                while ($ch -notmatch '^y$|^n$')
            }
            if ($confirm_spoti_recomended_uninstall) { $ch = 'y' }
            if ($confirm_spoti_recomended_over) { $ch = 'n' }
            if ($ch -eq 'y') {
                Write-Host ($lang).DelOld`n 
                $null = Unlock-Folder 
                cmd /c $spotifyExecutable /UNINSTALL /SILENT
                wait-process -name SpotifyUninstall
                Start-Sleep -Milliseconds 200
                if (Test-Path $spotifyDirectory) { Remove-Item -Recurse -Force -LiteralPath $spotifyDirectory }
                if (Test-Path $spotifyDirectory2) { Remove-Item -Recurse -Force -LiteralPath $spotifyDirectory2 }
                if (Test-Path $spotifyUninstall ) { Remove-Item -Recurse -Force -LiteralPath $spotifyUninstall }
            }
            if ($ch -eq 'n') { $ch = $null }
        }
        if ($ch -eq 'n') { 
            $downgrading = $true
        }
    }
    
}
# If there is no client or it is outdated, then install
if (-not $spotifyInstalled -or $upgrade_client) {

    Write-Host ($lang).DownSpoti"" -NoNewline
    Write-Host  $online -ForegroundColor Green
    Write-Host ($lang).DownSpoti2`n
    
    # Delete old version files of Spotify before installing, leave only profile files
    $ErrorActionPreference = 'SilentlyContinue'
    Kill-Spotify
    Start-Sleep -Milliseconds 600
    $null = Unlock-Folder 
    Start-Sleep -Milliseconds 200
    Get-ChildItem $spotifyDirectory -Exclude 'Users', 'prefs' | Remove-Item -Recurse -Force 
    Start-Sleep -Milliseconds 200

    # Client download
    downloadSp
    Write-Host

    Start-Sleep -Milliseconds 200

    # Client installation
    Start-Process -FilePath explorer.exe -ArgumentList $PWD\SpotifySetup.exe
    while (-not (get-process | Where-Object { $_.ProcessName -eq 'SpotifySetup' })) {}
    wait-process -name SpotifySetup
    Kill-Spotify

    # Upgrade check version Spotify offline
    $offline = (Get-Item $spotifyExecutable).VersionInfo.FileVersion

    # Upgrade check version Spotify.bak
    $offline_bak = (Get-Item $exe_bak).VersionInfo.FileVersion
}



# Delete Spotify shortcut if it is on desktop
if ($no_shortcut) {
    $ErrorActionPreference = 'SilentlyContinue'
    $desktop_folder = DesktopFolder
    Start-Sleep -Milliseconds 1000
    remove-item "$desktop_folder\Spotify.lnk" -Recurse -Force
}

$ch = $null

if ($podcasts_off) { 
    Write-Host ($lang).PodcatsOff`n 
    $ch = 'y'
}
if ($podcasts_on) {
    Write-Host ($lang).PodcastsOn`n
    $ch = 'n'
}
if (!($podcasts_off) -and !($podcasts_on)) {

    do {
        $ch = Read-Host -Prompt ($lang).PodcatsSelect
        Write-Host
        if (!($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue }
    }
    while ($ch -notmatch '^y$|^n$')
}
if ($ch -eq 'y') { $podcast_off = $true }

$ch = $null

if ($downgrading) { $upd = "`n" + [string]($lang).DowngradeNote }

else { $upd = "" }

if ($block_update_on) { 
    Write-Host ($lang).UpdBlock`n
    $ch = 'y'
}
if ($block_update_off) {
    Write-Host ($lang).UpdUnblock`n
    $ch = 'n'
}
if (!($block_update_on) -and !($block_update_off)) {
    do {
        $text_upd = [string]($lang).UpdSelect + $upd
        $ch = Read-Host -Prompt $text_upd
        Write-Host
        if (!($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue } 
    }
    while ($ch -notmatch '^y$|^n$')
}
if ($ch -eq 'y') { $not_block_update = $false }

if (!($new_theme) -and [version]$offline -ge [version]"1.2.14.1141") {
    Write-Warning "This version does not support the old theme, use version 1.2.13.661 or below"
    Write-Host
}

if ($ch -eq 'n') {
    $not_block_update = $true
    $ErrorActionPreference = 'SilentlyContinue'
    if ((Test-Path -LiteralPath $exe_bak) -and $offline -eq $offline_bak) {
        Remove-Item $spotifyExecutable -Recurse -Force
        Rename-Item $exe_bak $spotifyExecutable
    }
}

$ch = $null

$webjson = Get -Url (Get-Link -e "/patches.json") -RetrySeconds 5
        
if ($webjson -eq $null) { 
    Write-Host
    Write-Host "Failed to get patches.json" -ForegroundColor Red
    Write-Host ($lang).StopScript
    $tempDirectory = $PWD
    Pop-Location
    Start-Sleep -Milliseconds 200
    Remove-Item -Recurse -LiteralPath $tempDirectory 
    Pause
    Exit

}

function extract ($counts, $method, $name, $helper, $add, $patch) {
    switch ( $counts ) {
        "one" { 
            if ($method -eq "zip") {
                Add-Type -Assembly 'System.IO.Compression.FileSystem'
                $xpui_spa_patch = Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui.spa'
                $zip = [System.IO.Compression.ZipFile]::Open($xpui_spa_patch, 'update')   
                $file = $zip.GetEntry($name)
                $reader = New-Object System.IO.StreamReader($file.Open())
            }
            if ($method -eq "nonezip") {
                $file = get-item $env:APPDATA\Spotify\Apps\xpui\$name
                $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $file
            }
            $xpui = $reader.ReadToEnd()
            $reader.Close()
            if ($helper) { $xpui = Helper -paramname $helper } 
            if ($method -eq "zip") { $writer = New-Object System.IO.StreamWriter($file.Open()) }
            if ($method -eq "nonezip") { $writer = New-Object System.IO.StreamWriter -ArgumentList $file }
            $writer.BaseStream.SetLength(0)
            $writer.Write($xpui)
            if ($add) { $add | foreach { $writer.Write([System.Environment]::NewLine + $PSItem ) } }
            $writer.Close()  
            if ($method -eq "zip") { $zip.Dispose() }
        }
        "more" {  
            Add-Type -Assembly 'System.IO.Compression.FileSystem'
            $xpui_spa_patch = Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui.spa'
            $zip = [System.IO.Compression.ZipFile]::Open($xpui_spa_patch, 'update') 
            $zip.Entries | Where-Object { $_.FullName -like $name -and $_.FullName.Split('/') -notcontains 'spotx-helper' } | foreach { 
                $reader = New-Object System.IO.StreamReader($_.Open())
                $xpui = $reader.ReadToEnd()
                $reader.Close()
                $xpui = Helper -paramname $helper 
                $writer = New-Object System.IO.StreamWriter($_.Open())
                $writer.BaseStream.SetLength(0)
                $writer.Write($xpui)
                $writer.Close()
            }
            $zip.Dispose()
        }
        "exe" {
            $ANSI = [Text.Encoding]::GetEncoding(1251)
            $xpui = [IO.File]::ReadAllText($spotifyExecutable, $ANSI)
            $xpui = Helper -paramname $helper
            [IO.File]::WriteAllText($spotifyExecutable, $xpui, $ANSI)
        }
    }
}

function injection {
    param(
        [Alias("p")]
        [string]$ArchivePath,

        [Alias("f")]
        [string]$FolderInArchive,

        [Alias("n")]
        [string[]]$FileNames, 

        [Alias("c")]
        [string[]]$FileContents,

        [Alias("i")]
        [string[]]$FilesToInject  # force only specific file/files to connect index.html otherwise all will be connected
    )

    $folderPathInArchive = "$($FolderInArchive)/"

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::Open($ArchivePath, 'Update')
    
    try {
        for ($i = 0; $i -lt $FileNames.Length; $i++) {
            $fileName = $FileNames[$i]
            $fileContent = $FileContents[$i]

            $entry = $archive.GetEntry($folderPathInArchive + $fileName)
            if ($entry -eq $null) {
                $stream = $archive.CreateEntry($folderPathInArchive + $fileName).Open()
            }
            else {
                $stream = $entry.Open()
            }

            $writer = [System.IO.StreamWriter]::new($stream)
            $writer.Write($fileContent)

            $writer.Dispose()
            $stream.Dispose()
        }

        $indexEntry = $archive.Entries | Where-Object { $_.FullName -eq "index.html" }
        if ($indexEntry -ne $null) {
            $indexStream = $indexEntry.Open()
            $reader = [System.IO.StreamReader]::new($indexStream)
            $indexContent = $reader.ReadToEnd()
            $reader.Dispose()
            $indexStream.Dispose()

            $headTagIndex = $indexContent.IndexOf("</head>")
            $scriptTagIndex = $indexContent.IndexOf("<script")

            if ($headTagIndex -ge 0 -or $scriptTagIndex -ge 0) {
                $filesToInject = if ($FilesToInject) { $FilesToInject } else { $FileNames }

                foreach ($fileName in $filesToInject) {
                    if ($fileName.EndsWith(".js")) {
                        $modifiedIndexContent = $indexContent.Insert($scriptTagIndex, "<script defer=`"defer`" src=`"/$FolderInArchive/$fileName`"></script>")
                        $indexContent = $modifiedIndexContent
                    }
                    elseif ($fileName.EndsWith(".css")) {
                        $modifiedIndexContent = $indexContent.Insert($headTagIndex, "<link href=`"/$FolderInArchive/$fileName`" rel=`"stylesheet`">")
                        $indexContent = $modifiedIndexContent
                    }
                }

                $indexEntry.Delete()
                $newIndexEntry = $archive.CreateEntry("index.html").Open()
                $indexWriter = [System.IO.StreamWriter]::new($newIndexEntry)
                $indexWriter.Write($indexContent)
                $indexWriter.Dispose()
                $newIndexEntry.Dispose()

            }
            else {
                Write-Warning "<script or </head> tag was not found in the index.html file in the archive."
            }
        }
        else {
            Write-Warning "index.html not found in xpui.spa"
        }
    }
    finally {
        if ($archive -ne $null) {
            $archive.Dispose()
        }
    }
}


function Extract-WebpackModules {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputFile
    )

    $scriptStart = Get-Date
    Write-Debug "=== Script execution started ==="
    Write-Debug "Input file: $InputFile"

    function Encode-UTF16LE {
        param([byte[]]$Bytes)
        $str = [System.Text.Encoding]::UTF8.GetString($Bytes)
        [System.Text.Encoding]::Unicode.GetBytes($str)
    }

    $StartMarker = [System.Text.Encoding]::UTF8.GetBytes("var __webpack_modules__={")
    $EndMarker = [System.Text.Encoding]::UTF8.GetBytes("//# sourceMappingURL=xpui-modules.js.map")

    [byte[]]$fileContent = [System.IO.File]::ReadAllBytes($InputFile)

    $isUTF16LE = $false
    if ($fileContent.Length -ge 2 -and $fileContent[0] -eq 0xFF -and $fileContent[1] -eq 0xFE) {
        $isUTF16LE = $true
    }
    elseif ($fileContent.Length -gt 100 -and $fileContent[1] -eq 0x00) {
        $isUTF16LE = $true
    }
    if (-not $isUTF16LE) {
        Write-Error "File is not in UTF-16LE format: $InputFile"
        exit 1
    }

    $searchStartMarker = Encode-UTF16LE -Bytes $StartMarker
    $searchEndMarker = Encode-UTF16LE -Bytes $EndMarker

    function IndexOfBytes($haystack, $needle, [int]$startIndex = 0) {
        if ($startIndex -lt 0) { $startIndex = 0 }
        $haystackLength = $haystack.Length
        $needleLength = $needle.Length
        $searchLimit = $haystackLength - $needleLength
        if ($searchLimit -lt $startIndex) { return -1 }
        $firstNeedleByte = $needle[0]
        for ($i = $startIndex; $i -le $searchLimit; $i++) {
            if ($haystack[$i] -eq $firstNeedleByte) {
                $found = $true
                for ($j = 1; $j -lt $needleLength; $j++) {
                    if ($haystack[$i + $j] -ne $needle[$j]) {
                        $found = $false
                        break
                    }
                }
                if ($found) { return $i }
            }
        }
        return -1
    }

    $startIdx = IndexOfBytes $fileContent $searchStartMarker 2
    if ($startIdx -eq -1) {
        Write-Error "Start marker not found"
        exit 1
    }
    Write-Debug "Start marker found at index $startIdx"

    $endMarkerSearchOffset = $startIdx + $searchStartMarker.Length
    $endIdx = IndexOfBytes $fileContent $searchEndMarker $endMarkerSearchOffset
    if ($endIdx -eq -1) {
        Write-Error "End marker not found after index $endMarkerSearchOffset"
        exit 1
    }
    Write-Debug "End marker found at absolute index $endIdx"

    $endDataIdx = $endIdx + $searchEndMarker.Length
    $length = $endDataIdx - $startIdx

    Write-Debug "Decoding data from UTF-16LE..."
    $decodedString = [System.Text.Encoding]::Unicode.GetString($fileContent, $startIdx, $length)

    $scriptEnd = Get-Date
    $duration = [math]::Round(($scriptEnd - $scriptStart).TotalSeconds, 1)
    Write-Debug "=== Execution completed in $duration seconds ==="

    return $decodedString
}


function Update-ZipEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [System.IO.Compression.ZipArchive]$archive,
        [Parameter(Mandatory)]
        [string]$entryName,
        [string]$newEntryName = $null,
        [string]$prepend = $null,
        [scriptblock]$contentTransform = $null
    )

    $entry = $archive.GetEntry($entryName)
    if ($entry) {
        Write-Verbose "Updating entry: $entryName"
        $streamReader = $null
        $content = ''
        try {
            $streamReader = New-Object System.IO.StreamReader($entry.Open(), [System.Text.Encoding]::UTF8)
            $content = $streamReader.ReadToEnd()
        }
        finally {
            if ($null -ne $streamReader) {
                $streamReader.Close()
            }
        }

        $entry.Delete()

        if ($prepend) { $content = "$prepend`n$content" }
        if ($contentTransform) { $content = & $contentTransform $content }

        $finalEntryName = if ($newEntryName) { $newEntryName } else { $entryName }
        Write-Verbose "Creating new entry: $finalEntryName"

        $newEntry = $archive.CreateEntry($finalEntryName)
        $streamWriter = $null
        try {
            $streamWriter = New-Object System.IO.StreamWriter($newEntry.Open(), [System.Text.Encoding]::UTF8)
            $streamWriter.Write($content)
            $streamWriter.Flush()
        }
        finally {
            if ($null -ne $streamWriter) {
                $streamWriter.Close()
            }
        }
        Write-Verbose "Entry $finalEntryName updated successfully."
    }
    else {
        Write-Warning "Entry '$entryName' not found in archive."
    }
}


Write-Host ($lang).ModSpoti`n

$tempDirectory = $PWD
Pop-Location

Start-Sleep -Milliseconds 200
Remove-Item -Recurse -LiteralPath $tempDirectory 

$xpui_spa_patch = Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui.spa'
$xpui_js_patch = Join-Path (Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui') 'xpui.js'
$test_spa = Test-Path -Path $xpui_spa_patch
$test_js = Test-Path -Path $xpui_js_patch
$spotify_exe_bak_patch = Join-Path $env:APPDATA 'Spotify\Spotify.bak'


if ($test_spa -and $test_js) {
    Write-Host ($lang).Error -ForegroundColor Red
    Write-Host ($lang).FileLocBroken
    Write-Host ($lang).StopScript
    pause
    Exit
}

if ($test_js) {
    
    do {
        $ch = Read-Host -Prompt ($lang).Spicetify
        Write-Host
        if (!($ch -eq 'n' -or $ch -eq 'y')) { incorrectValue }
    }
    while ($ch -notmatch '^y$|^n$')

    if ($ch -eq 'y') { 
        $Url = "https://telegra.ph/SpotX-FAQ-09-19#Can-I-use-SpotX-and-Spicetify-together?"
        Start-Process $Url
    }

    Write-Host ($lang).StopScript
    Pause
    Exit
}  

if (!($test_js) -and !($test_spa)) { 
    Write-Host "xpui.spa not found, reinstall Spotify"
    Write-Host ($lang).StopScript
    Pause
    Exit
}

if ($test_spa) {
    
    Add-Type -Assembly 'System.IO.Compression.FileSystem'
    
    # Check for the presence of xpui.js in the xpui.spa archive

    $archive_spa = $null

    try {
        $archive_spa = [System.IO.Compression.ZipFile]::OpenRead($xpui_spa_patch)
        $xpuiJsEntry = $archive_spa.GetEntry('xpui.js')
        $xpuiSnapshotEntry = $archive_spa.GetEntry('xpui-snapshot.js')

        if (($null -eq $xpuiJsEntry) -and ($null -ne $xpuiSnapshotEntry)) {
        
            $snapshot_x64 = Join-Path $spotifyDirectory 'v8_context_snapshot.bin'
            $snapshot_arm64 = Join-Path $spotifyDirectory 'v8_context_snapshot.arm64.bin'

            $v8_snapshot = switch ($true) {
                { Test-Path $snapshot_x64 } { $snapshot_x64; break }
                { Test-Path $snapshot_arm64 } { $snapshot_arm64; break }
                default { $null }
            }

            if ($v8_snapshot) {
                $modules = Extract-WebpackModules -InputFile $v8_snapshot

                $firstLine = ($modules -split "`r?`n" | Select-Object -First 1)

                $archive_spa.Dispose()
                $archive_spa = [System.IO.Compression.ZipFile]::Open($xpui_spa_patch, [System.IO.Compression.ZipArchiveMode]::Update)

                Update-ZipEntry -archive $archive_spa -entryName 'xpui-snapshot.js' -prepend $firstLine -newEntryName 'xpui.js' -Verbose:$VerbosePreference
            
                Update-ZipEntry -archive $archive_spa -entryName 'xpui-snapshot.css' -newEntryName 'xpui.css' -Verbose:$VerbosePreference
            
                Update-ZipEntry -archive $archive_spa -entryName 'index.html' -contentTransform {
                    param($c)
                    $c = $c -replace 'xpui-snapshot.js', 'xpui.js'
                    $c = $c -replace 'xpui-snapshot.css', 'xpui.css'
                    return $c
                } -Verbose:$VerbosePreference
            }
            else {
                Write-Warning "v8_context_snapshot file not found"
            }
        }
    }
    catch {
        Write-Warning "Error: $($_.Exception.Message)"
    }
    finally {
        if ($null -ne $archive_spa) {
            $archive_spa.Dispose()
        }
    }

    $bak_spa = Join-Path (Join-Path $env:APPDATA 'Spotify\Apps') 'xpui.bak'
    $test_bak_spa = Test-Path -Path $bak_spa

    # Make a backup copy of xpui.spa if it is original
    $zip = [System.IO.Compression.ZipFile]::Open($xpui_spa_patch, 'update')
    $entry = $zip.GetEntry('xpui.js')
    $reader = New-Object System.IO.StreamReader($entry.Open())
    $patched_by_spotx = $reader.ReadToEnd()
    $reader.Close()

    If ($patched_by_spotx -match 'patched by spotx') {
        $zip.Dispose()    

        if ($test_bak_spa) {
            Remove-Item $xpui_spa_patch -Recurse -Force
            Rename-Item $bak_spa $xpui_spa_patch

            $spotify_exe_bak_patch = Join-Path $env:APPDATA 'Spotify\Spotify.bak'
            $test_spotify_exe_bak = Test-Path -Path $spotify_exe_bak_patch
            if ($test_spotify_exe_bak) {
                Remove-Item $spotifyExecutable -Recurse -Force
                Rename-Item $spotify_exe_bak_patch $spotifyExecutable
            }
        }
        else {
            Write-Host ($lang).NoRestore`n
            Pause
            Exit
        }
        $spotify_exe_bak_patch = Join-Path $env:APPDATA 'Spotify\Spotify.bak'
        $test_spotify_exe_bak = Test-Path -Path $spotify_exe_bak_patch
        if ($test_spotify_exe_bak) {
            Remove-Item $spotifyExecutable -Recurse -Force
            Rename-Item $spotify_exe_bak_patch $spotifyExecutable
        }
    }
    $zip.Dispose()
    Copy-Item $xpui_spa_patch $env:APPDATA\Spotify\Apps\xpui.bak

    # Full screen mode activation and removing "Upgrade to premium" menu, upgrade button, disabling a playlist sponsor
    if (!($premium)) {
        extract -counts 'one' -method 'zip' -name 'xpui.js' -helper 'OffadsonFullscreen'
    }

    # Forced exp
    extract -counts 'one' -method 'zip' -name 'xpui.js' -helper 'ForcedExp' -add $webjson.others.byspotx.add

    # Hiding Ad-like sections or turn off podcasts from the homepage
    if ($podcast_off -or $adsections_off -or $canvashome_off) {

        $section = Get -Url (Get-Link -e "/sectionBlock.js")
        
        if ($section -ne $null) {

            injection -p $xpui_spa_patch -f "spotx-helper" -n "sectionBlock.js" -c $section
        }
        else {
            $podcast_off, $adsections_off = $false
        }
    }

    # Static color for lyrics
    if ($lyrics_stat) {
        $rulesContent = Get -Url (Get-Link -e "/rules.css")
        $colorsContent = Get -Url (Get-Link -e "/colors.css")

        $colorsContent = $colorsContent -replace '{{past}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.pasttext)"
        $colorsContent = $colorsContent -replace '{{current}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.current)"
        $colorsContent = $colorsContent -replace '{{next}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.next)"
        $colorsContent = $colorsContent -replace '{{hover}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.hover)"
        $colorsContent = $colorsContent -replace '{{background}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.background)"
        $colorsContent = $colorsContent -replace '{{musixmatch}}', "$($webjson.others.themelyrics.theme.$lyrics_stat.maxmatch)"

        injection -p $xpui_spa_patch -f "spotx-helper/lyrics-color" -n @("rules.css", "colors.css") -c @($rulesContent, $colorsContent) -i "rules.css"

    }
    extract -counts 'one' -method 'zip' -name 'xpui.js' -helper 'VariousofXpui-js'
    
    if ([version]$offline -ge [version]"1.2.28.581" -and [version]$offline -le [version]"1.2.57.463") {
        
        if ([version]$offline -ge [version]"1.2.45.454") { $typefile = "xpui.js" }

        else { $typefile = "xpui-routes-search.js" }

        extract -counts 'one' -method 'zip' -name $typefile -helper "Fixjs"
    }
    

    if ($devtools -and [version]$offline -ge [version]"1.2.35.663") {
        extract -counts 'one' -method 'zip' -name 'xpui-routes-desktop-settings.js' -helper 'Dev' 
    }

    # Hide Collaborators icon
    if (!($hide_col_icon_off) -and !($exp_spotify)) {
        extract -counts 'one' -method 'zip' -name 'xpui-routes-playlist.js' -helper 'Collaborators'
    }

    # Add discriptions (xpui-desktop-modals.js)
    extract -counts 'one' -method 'zip' -name 'xpui-desktop-modals.js' -helper 'Discriptions'

    # Disable Sentry 
    if ( [version]$offline -le [version]"1.2.56.502" ) {  
        $fileName = 'vendor~xpui.js'

    }
    else { $fileName = 'xpui.js' }

    extract -counts 'one' -method 'zip' -name $fileName -helper 'DisableSentry'

    # Minification of all *.js
    extract -counts 'more' -name '*.js' -helper 'MinJs'

    # xpui.css
    if (!($premium)) {
        # Hide download block
        if ([version]$offline -ge [version]"1.2.30.1135") {
            $css += $webjson.others.downloadquality.add
        }
        # Hide download icon on different pages
        $css += $webjson.others.downloadicon.add
        # Hide submenu item "download"
        $css += $webjson.others.submenudownload.add
        # Hide very high quality streaming
        if ([version]$offline -le [version]"1.2.29.605") {
            $css += $webjson.others.veryhighstream.add
        }
    }
    # block subfeeds
    if ($global:type -match "all" -or $global:type -match "podcast") {
        $css += $webjson.others.block_subfeeds.add
    }
    # scrollbar indent fixes
    $css += $webjson.others.'fix-scrollbar'.add

    if ($null -ne $css ) { extract -counts 'one' -method 'zip' -name 'xpui.css' -add $css }
    
    # Old UI fix
    $contents = "fix-old-theme"
    extract -counts 'one' -method 'zip' -name 'xpui.css' -helper "FixCss"

    # Remove RTL and minification of all *.css
    extract -counts 'more' -name '*.css' -helper 'Cssmin'
    
    # licenses.html minification

    extract -counts 'one' -method 'zip' -name 'licenses.html' -helper 'HtmlLicMin'
    # blank.html minification
    extract -counts 'one' -method 'zip' -name 'blank.html' -helper 'HtmlBlank'
    
    # Minification of all *.json
    extract -counts 'more' -name '*.json' -helper 'MinJson'
}

# Create a desktop shortcut
$ErrorActionPreference = 'SilentlyContinue' 

if (!($no_shortcut)) {

    $desktop_folder = DesktopFolder

    If (!(Test-Path $desktop_folder\Spotify.lnk)) {
        $source = Join-Path $env:APPDATA 'Spotify\Spotify.exe'
        $target = "$desktop_folder\Spotify.lnk"
        $WorkingDir = "$env:APPDATA\Spotify"
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($target)
        $Shortcut.WorkingDirectory = $WorkingDir
        $Shortcut.TargetPath = $source
        $Shortcut.Save()      
    }
}

# Create shortcut in start menu
If (!(Test-Path $start_menu)) {
    $source = Join-Path $env:APPDATA 'Spotify\Spotify.exe'
    $target = $start_menu
    $WorkingDir = "$env:APPDATA\Spotify"
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($target)
    $Shortcut.WorkingDirectory = $WorkingDir
    $Shortcut.TargetPath = $source
    $Shortcut.Save()      
}

$ANSI = [Text.Encoding]::GetEncoding(1251)
$old = [IO.File]::ReadAllText($spotifyExecutable, $ANSI)

$regex1 = $old -notmatch $webjson.others.binary.block_update.add
$regex2 = $old -notmatch $webjson.others.binary.block_slots.add
$regex3 = $old -notmatch $webjson.others.binary.block_slots_2.add
$regex4 = $old -notmatch $webjson.others.binary.block_slots_3.add
$regex5 = $old -notmatch $webjson.others.binary.block_gabo.add

if ($regex1 -and $regex2 -and $regex3 -and $regex4 -and $regex5) {

    if (Test-Path -LiteralPath $exe_bak) { 
        Remove-Item $exe_bak -Recurse -Force
        Start-Sleep -Milliseconds 150
    }
    copy-Item $spotifyExecutable $exe_bak
}

# Binary patch
extract -counts 'exe' -helper 'Binary'

# Disable Startup client
if ($DisableStartup) {
    $prefsPath = "$env:APPDATA\Spotify\prefs"
    $keyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $keyName = "Spotify"

    # delete key in registry
    if (Get-ItemProperty -Path $keyPath -Name $keyName -ErrorAction SilentlyContinue) {
        Remove-ItemProperty -Path $keyPath -Name $keyName -Force
    } 

    # create new prefs
    if (-not (Test-Path $prefsPath)) {
        $content = @"
app.autostart-configured=true
app.autostart-mode="off"
"@
        [System.IO.File]::WriteAllLines($prefsPath, $content, [System.Text.UTF8Encoding]::new($false))
    }
    
    # update prefs
    else {
        $content = [System.IO.File]::ReadAllText($prefsPath)
        if (-not $content.EndsWith("`n")) {
            $content += "`n"
        }
        $content += 'app.autostart-mode="off"'
        [System.IO.File]::WriteAllText($prefsPath, $content, [System.Text.UTF8Encoding]::new($false))
    }

}

# Start Spotify
if ($start_spoti) { Start-Process -WorkingDirectory $spotifyDirectory -FilePath $spotifyExecutable }

Write-Host ($lang).InstallComplete`n -ForegroundColor Green
