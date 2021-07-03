# BTTspeedUtilities
Various utilities to improve BTT income with uTorrent and Bittorrent torrent clients.

# Torrent Pruning
This PowerShell script will automatically prune torrents which exceed a certain age. Works will with automated methods of adding torrents so that you constantly have fresh content (check out [Jackett](https://github.com/Jackett/Jackett)). Requires you enable the WebGUI in the torrent client. Configure the settings in the script prior to use.

[uTorrent-Prune-Old-Torrents.ps1](https://github.com/ArchiRocksTech/BTTspeedUtilities/blob/main/uTorrent-Prune-Old-Torrents.ps1)

# Ban non-BTT-Speed clients
A PowerShell script that helps to ensure you maximize your BTT income potential by only allowing clients which support BTT Speed. It offers two methods, the IPFilter.dat of the torrent client and the Windows Firewall. You can enable one or both. Requires you enable the WebGUI in the torrent client. Configure the settings in the script prior to use.
[ComingSoonTM](https://github.com/ArchiRocksTech/BTTspeedUtilities)

# BTT Exchange Wallet Balance Monitor
A Telegram group with a bot that auto messages when the BTT Exchange wallet balance changes by more than 999 BTT. Allows you to monitor the balance changes and know when there are enough BTT to perform a withdraw.

**[Join us](https://t.me/bttexchangewalletbalance)**

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
