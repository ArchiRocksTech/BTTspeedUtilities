# BTTspeedUtilities
A collection of various utilities to improve BTT income with [µTorrent](https://www.utorrent.com/downloads/complete/track/stable/os/win) and [BitTorrent](https://www.bittorrent.com/downloads/complete/classic/) torrent clients. 
Earn BTT with [BitTorrent Speed](https://www.bittorrent.com/token/bittorrent-speed/).

# Torrent Pruning
This PowerShell script will automatically prune torrents which exceed a certain age. Works will with automated methods of adding torrents so that you constantly have fresh content (check out [Jackett](https://github.com/Jackett/Jackett)). Requires you enable the WebGUI in the torrent client. Configure the settings in the script prior to use.

[uTorrent-Prune-Old-Torrents.ps1](https://github.com/ArchiRocksTech/BTTspeedUtilities/blob/main/uTorrent-Prune-Old-Torrents.ps1)

# Ban non-BTT-Speed clients
A PowerShell script that helps to ensure you maximize your BTT income potential by only allowing clients which support BTT Speed. It offers two methods, the IPFilter.dat of the torrent client and the Windows Firewall. You can enable one or both. Requires you enable the WebGUI in the torrent client. Configure the settings in the script prior to use.
[ComingSoonTM](https://github.com/ArchiRocksTech/BTTspeedUtilities)

# BTT Exchange Wallet Balance Monitor
A Telegram group with a bot that auto messages when the BTT Exchange wallet balance changes by more than 999 BTT. Allows you to monitor the balance changes and know when there are enough BTT to perform a withdraw.

**[Join us](https://t.me/bttexchangewalletbalance)**

# Donations
*Never expected, always welcome and appreciated.*
* BTC `bc1q6g7rg5xryumgygmysq5zwe0svc0jmzpazz75p8`
* ETH / ERC20 `0x2406ba931307e56f4DB506099Eb09224223CF4E8`
* TRX / BTT / USDT-TRC10 `TNRtWbQQ9aCTtQYLEePFGSBwEBvhHsa1Ye`
* DOT `14T62EomidLtwXDZsKSJ4usfm8q4UJoq1y926XG3zzbJGCMB`
* XTZ `tz1WwTjCvjxc1yeze2xMBWdyApwfHacBhh5v`
* ADA `addr1q8c9gur0mam0h69h7pttgd2vfdugl6vack42l38r7hfj2r0s23cxlhmkl05t0uzkks65cjmc3l5em3d24lzw8awny5xst84y5r`
* BNB `bnb1tw8pd7tx8m8tfcjcqkl5fp98xzvxh9u2j29kh0`
* XLM `GBOX5QQ72BPSA5ZYPN5Q5WLBRY3TTQXFU4SBLGKMAR7BS7UAR45GLXVQ`
* ONT `AG78qWzQcdwdGH7hPzxTFH7mLf8qtwz6UV`
* ATOM `cosmos1ppd4hkaznks8qhwj0v4yacmznh995s9wp2cfa2`
* DAI `0x2406ba931307e56f4DB506099Eb09224223CF4E8`
* ALGO `GLNUFUVHS4VOCLPG73S63XN3YKIC2K3XVSNA64N75YATXKITWPWBESNTK4`
* XRP `rDWb7F719h4E78GaiKpQodhk2GPJaic8Pt`
* DOGE `DRVQaveJRTeuka2sdzxRFGnw6FYzt6waTB`
* LTC `LSnLZS6L8xSJxCTpiUicVmDmfT8cV3dpsj`
* SuperDoge `SMMJQJRDymSqcZZkPihpsDrEc3dZaMvmY4`

# Troubleshooting

**ERROR**: [ScriptName] cannot be loaded because running scripts is disabled on this system.

**SOLUTION**: Enable running PowerShell scripts by adjusting the Execution Policy on your system.

Use the execution policy that allows the script to work.

The Set-ExecutionPolicy cmdlet enables you to determine which Windows PowerShell scripts (if any) will be allowed to run on your computer. 

Windows PowerShell has four different execution policies:

* Restricted - No scripts can be run. Windows PowerShell can be used only in interactive mode.
* AllSigned - Only scripts signed by a trusted publisher can be run.
* RemoteSigned - Downloaded scripts must be signed by a trusted publisher before they can be run.
* Unrestricted - No restrictions; all Windows PowerShell scripts can be run.

To assign a particular policy simply call Set-ExecutionPolicy followed by the appropriate policy name. For example, this command run in a PowerShell console sets the execution policy to RemoteSigned:

`Set-ExecutionPolicy RemoteSigned`

To run this in a Command Prompt console, use the following command:

`PowerShell Set-ExecutionPolicy RemoteSigned`

Source: [Microsoft Docs](https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-powershell-1.0/ee176961(v=technet.10)?redirectedfrom=MSDN)
