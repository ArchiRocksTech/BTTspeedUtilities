# PowerShell Torrent Manager
# For uTorrent and BitTorrent clients

# -- Ban non-BTT Clients
# -- Prune Old Torrents
# -- Configure Client Settings
# 
# To utilize, edit the settings below to match your client and desired configuration.
# Save and Exit, then right-click this file, and click Run with PowerShell.
#
# To stop the script, press CTRL+C.

## -- Shared Settings
# WebUI Settings, as configured in your client
# WebUI Username
$user = 'admin'
# WebUI Password
$pass = 'abc123'
# WebUI Port
$port = '50000'
# uTorrent / BitTorrent client folder - 'C:\Users\Administrator\AppData\Roaming\uTorrent'
$clientPath = 'C:\Users\Administrator\AppData\Roaming\uTorrent'
# Default Operation frequency in seconds. (Number. Default: 30)
$freq = 30


## -- Client Banning Settings
# Show banned clients to console? ($true or $false. Default: $false) - Better performance with $false.
$showBanned = $false
# Allowed Client Versions, minimum. These clients are allowed to connect, others will be banned.
# uTorrent
$minUTorrent = "3.5.5" # Default: "3.5.5"
# uTorrent Mac
$minUTorrentMac = "0.0" # Default: "0.0"
# BitTorrent
$minBittorrent = "7.10" # Default: "7.10"
# libTorrent
$minLibTorrent = "1.1.13.1" # Default: "1.1.13.1"
# Block the clients with the *Torrent IP Blocking feature, IPFilter.dat? ($true or $false. Default: $true)
$blockClientsInClient = $true
# Start Fresh? Wipes IPFilter.dat at start. ($true or $false. Default: $true)
$freshStart = $true

## -- Torrent Pruning Settings
# Prune old torrents? If $false, it will only list torrents and age. ($true or $false. Default: $false)
$pruneTorrents = $false
# Prune torrents older than X hours old. (Number. Default: 36)
$pruneOlderThan = 36
# Remove Torrent and Data, or just Torrent? ($true or $false. Default: $false)
$removeData = $false
# NOTE when setting $removeData to $true: 
 # If you want deleted data to skip the recycle bin and be permanaently deleted, you must
 # change the setting in the torrent client. Advanced: gui.delete_to_trash = false
# Pruning Frequency in minutes (Number. Default: 60)
$pruneFreq = 60
# Exclude labels(s). Torrents with any of these labels will not be pruned. (Default: @('keep','hold') )
$excludeThese = @('keep','hold')
# Exclude torrents with high upload speeds (might be money makers) (Default: 75)
$excludeAboveSpeed = 75 #Kb/s

## -- Torrent Client Settings
# Max Download Slots (Number. Default: 0)(Disable script configuration of slots: -1)
$maxDLslots = 0

#======== CHANGE NOTHING BELOW ===============================
#Requires -Version 5.1
# ======================================================================================
$host.UI.RawUI.WindowTitle = "PowerShell Torrent Managers"
$baseURL = "http://127.0.0.1:$port/gui"

$ipFilterFile = 'ipfilter.dat'
$ipDB = "$clientPath\$ipFilterFile"
If (Test-Path -ErrorAction SilentlyContinue -Path $ipDB) {
    Write-Host "ipfilter.dat found" -ForegroundColor Yellow
} Else {
    Write-Host "ipfilter.dat not found, it will be created" -ForegroundColor Yellow    
    $path = (Get-Process | Where-Object {$_.Name -eq "uTorrent" -or $_.Name -eq "bittorrent"}).path
    $clientPath = $path.Substring(0,$path.LastIndexOf("\"))    
}

$stopIt = $false
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
    $errorMessage = $_.Exception.Message; Write-Host $errorMessage -ForegroundColor Red
    Pause
    break
}

If ($freshStart -eq $true) {
    # Empty the IPFilter.dat, have client refresh its list
    Set-Content -Path $ipDB -Value $null
    Try { $setFilter = Invoke-WebRequest -Uri $($baseURL + "/?action=setsetting&s=ipfilter.enable&v=1" + "&token=" + $token) -Headers $Headers -Method Get -WebSession $session -ErrorAction SilentlyContinue -ErrorVariable webERR -UseBasicParsing
    } Catch {}
}

$lastPrune = (Get-Date)
$tzOffset = ([TimeZoneInfo]::Local).BaseUtcOffset
If ((get-date).IsDaylightSavingTime()){$dlsOffset = (Get-CimInstance win32_timezone).DaylightBias} Else {$dlsOffset = 0}

do {
    Clear-Host
    $start = Get-Date
    $allowed = 0; $banned = 0    
    $bannedIPs = @()
    $list = Invoke-WebRequest -Uri $($baseURL + '/?list=1' + "&token=" + $token) -Headers $Headers -Method Get -WebSession $session -UseBasicParsing
    $torrentHashRegEx = '([A-Z0-9]{40})'
    $torrentHashes = ([regex]::Matches($list.content,$torrentHashRegEx)).Value
    $currentIPDBcontent = @(Get-Content -Path $ipDB -ErrorAction SilentlyContinue)
    If ($currentIPDBcontent.Count -ge 10000) {        
        $currentIPDBcontent =  $currentIPDBcontent | Select-Object -Last 5000
    }
    
    $hashList = $null; $i = 0; $ii = 0; $finalHashes = $null
    ForEach ($hash in $torrentHashes) {
        $hashList += "&hash=$hash"
        $i ++ | Out-Null; $ii ++ | Out-Null        
        If ($i -eq 35 -or $ii -eq $torrentHashes.Count) {                
            $peerList = Invoke-WebRequest -Uri $($baseURL + "/?action=getpeers$hashList" + "&token=" + $token) -Headers $Headers -Method Get -WebSession $session -UseBasicParsing
            $hashList = $null; $i = 0
            $finalHashes += ($peerList.Content | ConvertFrom-Json).peers
        }
    }

    ForEach ($finalHash in $finalHashes | Where-Object {$_.SyncRoot}) {
        ForEach ($peer in $finalHash) {
            If ($peer[1].Trim() -match '^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$') {$IP = $peer[1].Trim()}
            $clientName =  $peer[5]
            #$clientSpeedUp = $peer[9]
            $clientVerRegex = '[1-9]\d*(\.[1-9]\d*)*$' #'(\d+)\.(\d+)\.?(\d*)\.?(\d*)'
            $ClientVersion = [regex]::Match($clientName, $clientVerRegex)            
            If ($ClientVersion.Success -eq $true) {
                $realVersion = Try {[version]$ClientVersion.value}Catch{[version]"0.0"}
                switch ($clientName) {
                    # Configure the allowed Clients with their allowed versions. All others are banned!

                    # μTorrent uses a unicode symbol that isn't properly deciphered on all systems. Using the byte character value to find it instead.
                    {
                        If ([byte][char]$clientName.Substring(0,1) -eq 206 -and [byte][char]$clientName.Substring(1,1) -eq 188){
                            # $MuFound = $true
                            $remainingName = $clientName.Substring(2,$clientName.Length -3)
                            If ($remainingName -like "Torrent*" -and $realVersion -ge [version]$minUTorrent -and $_ -notlike "*FAKE*") {
                                $true
                            }
                        }                    
                    }{$allowed++}
                    # μTorrent Mac - same note as above
                    {
                        If ([byte][char]$clientName.Substring(0,1) -eq 206 -and [byte][char]$clientName.Substring(1,1) -eq 188){
                            # $MuFound = $true
                            $remainingName = $clientName.Substring(2,$clientName.Length -3)
                            If ($remainingName -like "Torrent Mac*" -and $realVersion -ge [version]$minUTorrentMac -and $_ -notlike "*FAKE*") {
                                $true
                            }
                        }                    
                    }{$allowed++}

                    # These entries shouldn't be needed any more. Leaving as a fallback.
                    #{($_ -like "Ã‚ÂµTorrent*" -and $realVersion -ge [version]$minUTorrent) -and $_ -notlike "*FAKE*"}{$allowed++} # PowerShell doesn't like the Î¼ mu character
                    #{($_ -like "ÃŽÂ¼Torrent Mac*" -and $realVersion -ge [version]$minUTorrentMac)}{$allowed++} # PowerShell doesn't like the Î¼ mu character
                    #{($_ -like "ÃŽÂ¼Torrent*" -and $realVersion -ge [version]$minUTorrent) -and $_ -notlike "*FAKE*"}{$allowed++} # PowerShell doesn't like the Î¼ mu character
                    #{($_ -like "Î¼Torrent Mac*" -and $realVersion -ge [version]$minUTorrentMac)}{$allowed++} # PowerShell doesn't like the Î¼ mu character
                    #{($_ -like "Î¼Torrent*" -and $realVersion -ge [version]$minUTorrent) -and $_ -notlike "*FAKE*"}{$allowed++} # PowerShell doesn't like the Î¼ mu character
                    
                    {($_ -like "BitTorrent*" -and $realVersion -ge [version]$minBittorrent)}{$allowed++}
                    {($_ -like "libtorrent*" -and $realVersion -ge [version]$minLibTorrent)}{$allowed++} # Deluge uses libtorrent 1.1.13.0 on ubuntu, so use greater than to exclude it
                    {($_ -like "Unknown**" -and $realVersion -ge [version]"0.0") -and $_ -notlike "*FAKE*"}{$allowed++} # PowerShell doesn't like the Î¼ mu character
                    default {
                        If($currentIPDBcontent -notcontains $IP) {
                            If ($showBanned -eq $true){ Write-Host "[$(Get-Date)] Banned: $IP [$clientName]" -ForegroundColor Red }
                            $currentIPDBcontent += $IP
                            $banned++
                            $bannedIPs += $IP                            
                        }
                    }
                }
            } Else { 
                # no version code - banned
                If($currentIPDBcontent -notcontains $IP) {
                    If ($showBanned -eq $true){ Write-Host "[$(Get-Date)] Banned: $IP [$clientName]" -ForegroundColor Red }
                    $currentIPDBcontent += $IP
                    $banned++
                    $bannedIPs += $IP
                }
            }
        }
    }
    
    # Write out updated content
    If ($banned -gt 0 -and $blockClientsInClient -eq $true) {
        Set-Content -Path $ipDB -Value $currentIPDBcontent
        # Set IPfilter enabled - uTorrent will refresh its list
        $setFilter = Invoke-WebRequest -Uri $($baseURL + "/?action=setsetting&s=ipfilter.enable&v=1" + "&token=" + $token) -Headers $Headers -Method Get -WebSession $session -ErrorAction SilentlyContinue -ErrorVariable webERR -UseBasicParsing
    }

    If ($setFilter.StatusCode -eq 200) {
        Write-Host "[$(Get-Date)] Successfully enabled IPfilter [Allowed: $allowed][Banned: $banned][IPfilterCount: $($currentIPDBcontent.Count)]" -ForegroundColor Green
    } Else {
        Write-Host "[$(Get-Date)] Error enabling IPfilter [$webERR]" -ForegroundColor Red
    }
    
    $took = (New-TimeSpan -Start $start -End $(Get-Date)).TotalSeconds
    Write-Host "Client Banning Filtering took $took seconds" -ForegroundColor Cyan

    #region torrentPruning
    If ( (New-TimeSpan -Start $lastPrune -End (Get-Date) ).TotalMinutes -ge $pruneFreq){
        
        $list = Invoke-RestMethod -Uri $($baseURL + '/?list=1' + "&token=" + $token) -Headers $Headers -Method Get -WebSession $session -UseBasicParsing
        $info = $list.torrents | ConvertTo-Json | ConvertFrom-Json
        $torrentHashes = @()

        ForEach ($torrent in $info) {
            $hash = $torrent.value[0]
            $status = $torrent.value[21]
            $name = $torrent.value[2]
            $label = $torrent.value[11]
            $upSpeed = $torrent.value[13]            
            #$addedOn = $torrent.value[23] # You can use the added on value, but its preferrable to use the completed on value
            $completedOn = $torrent.value[24]
            #$AddedOnFromEpoch = ((Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($addedOn)) + $tzOffset).AddMinutes(-$dlsOffset)
            $CompletedOnFromEpoch =  ((Get-Date 01.01.1970)+([System.TimeSpan]::fromseconds($completedOn)) + $tzOffset).AddMinutes(-$dlsOffset)
            $age = [math]::Round( (New-TimeSpan -Start $CompletedOnFromEpoch -End (Get-Date)).TotalHours,2)
             Write-Host "[Age: $age hours][Speed: $upSpeed] $name" -ForegroundColor Cyan
            If ($age -ge $pruneOlderThan -and $status -eq "Seeding 100.0 %" -and ($excludeThese -notcontains $label) -and $upSpeed -lt $excludeAboveSpeed) {
                Write-Host "[Age: $age hours] $name" -ForegroundColor Cyan
                Write-Host "Pruning due to age" -ForegroundColor Yellow
                $torrentHashes += $hash
            } ElseIf ($excludeThese -contains $label) {
                Write-Host "[Age: $age hours] $name" -ForegroundColor Cyan
                Write-Host "^^ Excluded because of label: $label" -ForegroundColor Yellow
            }
        }

        $hashList = $null
        ForEach ($hash in $torrentHashes) { $hashList += "&hash=$hash" }
        If ($pruneTorrents -eq $true) {
            If ($removeData -eq $true) {
                Try {Invoke-WebRequest -Uri $($baseURL + "/?action=removedata$hashList" + "&token=" + $token) -Headers $Headers -Method Get -WebSession $session -UseBasicParsing | Out-Null}Catch{}
            } Else {
                Try {Invoke-WebRequest -Uri $($baseURL + "/?action=remove$hashList" + "&token=" + $token) -Headers $Headers -Method Get -WebSession $session -UseBasicParsing | Out-Null}Catch{}
            }
        }

        $lastPrune = (Get-Date)
    } Else {
        Write-Host "[Last Pruned] $lastPrune" -ForegroundColor Yellow
    }
    #endregion torrentPruning

    #region clientSettings
    If ($maxDLslots -ne -1){        
        Try {Invoke-WebRequest -Uri $($baseURL + "/?action=setsetting&s=max_active_downloads&v=$maxDLslots" + "&token=" + $token) -Headers $Headers -Method Get -WebSession $session -UseBasicParsing | Out-Null}Catch{}
    }
    #endregion clientSettings

    Start-Sleep -Seconds $freq
} until ($stopIt -eq $true)


