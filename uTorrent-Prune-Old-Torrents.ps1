# uTorrent Web GUI API interaction - PowerShell - Torrent Pruning
#
# To run, edit the settings below to match your client and desired pruning schedule.
# Save and Exit, then right-click this file, and click Run with PowerShell.
#
# To stop the script, press CTRL+C.

# WebUI Settings, as configured in your client
# WebUI Username
$user = 'admin'
# WebUI Password
$pass = 'abc123'
# WebUI Port
$port = '50000'

# Prune old torrents? If $false, it will only list torrents and age. ($true or $false. Default: $false)
$pruneTorrents = $false

# Prune torrents older than X hours old. (Number. Default: 36)
$pruneOlderThan = 36

# Prune every X minutes. (Number. Default: 60)
$reRunEveryXminutes = 60

# Remove Torrent and Data, or just Torrent? ($true or $false. Default: $false)
$removeData = $false

# CHANGE NOTHING BELOW =================================================================
# ======================================================================================
$host.UI.RawUI.WindowTitle = "uTorrent-Prune-Old-Torrents"
$baseURL = "http://127.0.0.1:$port/gui"
$pair = "$($user):$($pass)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$basicAuthValue = "Basic $encodedCreds"
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$Headers = @{
    Authorization = $basicAuthValue
    "Content-Type" = "text/plain"
    "charset" = "utf-8"
}
Try {
    $tokenResults = Invoke-WebRequest -Uri $($baseURL + '/token.html') -Headers $Headers -Method Get -WebSession $session -UseBasicParsing
    $regExOptions = [System.Text.RegularExpressions.RegexOptions]::Multiline
    $regExFilter = '^Set-Cookie:\sGUID=([a-zA-Z0-9]+);'
    $regExMatch = [regex]::Match($tokenResults.RawContent,$regExFilter,$regExOptions)
    $cookieValue = $regExMatch.Groups[1].Value
    $regExFilterToken = "<div\sid='token'\sstyle='display:none;'>(.+)<\/div>"
    $regExMatchToken = [regex]::Match($tokenResults.RawContent,$regExFilterToken,$regExOptions)
    $token = $regExMatchToken.Groups[1].Value    
    $cookie = New-Object System.Net.Cookie 
    $cookie.Name = "GUID"
    $cookie.Value = $cookieValue
    $cookie.Domain = "127.0.0.1"
    $cookie.Path = '/'
    $session.Cookies.Add($cookie);
} Catch {    
    Write-Host "Failed to query token and cookie information from the Client." -ForegroundColor Red
    Write-Host "Please ensure the configuration matches in the Client and this script and that the Client is currently running." -ForegroundColor Yellow
    Write-Host "Additional error information: " -NoNewline
    $errormessage = $_.Exception.Message; Write-Host $errormessage -ForegroundColor Red
    Pause
    break
}

$tzOffset = ([TimeZoneInfo]::Local).BaseUtcOffset
If ((get-date).IsDaylightSavingTime()){$dlsOffset = (Get-CimInstance win32_timezone).DaylightBias} Else {$dlsOffset = 0}

$stopIt = $false

Do {
    Clear-Host
    $list = Invoke-RestMethod -Uri $($baseURL + '/?list=1' + "&token=" + $token) -Headers $Headers -Method Get -WebSession $session -UseBasicParsing
    $info = $list.torrents | ConvertTo-Json | ConvertFrom-Json
    $torrentHashes = @()

    ForEach ($torrent in $info) {
        $hash = $torrent.value[0]
        $status = $torrent.value[21]
        $name = $torrent.value[2]
        #$addedOn = $torrent.value[23] # You can use the added on value, but its preferrable to use the completed on value
        $completedOn = $torrent.value[24]
        #$AddedOnFromEpoch = ((Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($addedOn)) + $tzOffset).AddMinutes(-$dlsOffset)
        $CompletedOnFromEpoch =  ((Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($completedOn)) + $tzOffset).AddMinutes(-$dlsOffset)
        $age = [math]::Round( (New-TimeSpan -Start $CompletedOnFromEpoch -End (Get-Date)).TotalHours,2)
        Write-Host "[Age: $age hours] $name" -ForegroundColor Cyan
        If ($age -ge $pruneOlderThan -and $status -eq "Seeding 100.0 %") {
            Write-Host "Pruning due to age: $name" -ForegroundColor Yellow
            $torrentHashes += $hash
        }
    }

    $hashList = $null
    ForEach ($hash in $torrentHashes) { $hashList += "&hash=$hash" }
    If ($pruneTorrents -eq $true) {
        If ($removeData -eq $true) {
            Invoke-WebRequest -Uri $($baseURL + "/?action=removedata$hashList" + "&token=" + $token) -Headers $Headers -Method Get -WebSession $session -UseBasicParsing | Out-Null
        } Else {
            Invoke-WebRequest -Uri $($baseURL + "/?action=remove$hashList" + "&token=" + $token) -Headers $Headers -Method Get -WebSession $session -UseBasicParsing | Out-Null
        }
    }

    Write-Host "Sleeping..." -ForegroundColor Cyan
    Start-Sleep -Seconds ($reRunEveryXminutes * 60)

} Until ($stopIt -eq $true)