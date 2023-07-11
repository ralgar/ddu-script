########################################
###   Update Nvidia Display Driver   ###
###############################################################################
# A Windows PowerShell script to cleanly update your Nvidia display driver,
#  using Display Driver Uninstaller and Chocolatey.

function Set-RunOnce($type) {
    Write-Host 'Writing RunOnce key...'
    $RunOnceKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    if ($type -eq 'SafeMode') {
        Set-ItemProperty -Path $RunOnceKey -Name "*DDUScript" -Value ('C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -executionPolicy Unrestricted -File ' + "$PSCommandPath")
    } else {
        Set-ItemProperty -Path $RunOnceKey -Name "DDUScript" -Value ('C:\Windows\System32\WindowsPowerShell\v1.0\Powershell.exe -executionPolicy Unrestricted -File ' + "$PSCommandPath")
    }
}

function Uninstall-DisplayDriver {
    Write-Host 'Cleaning display driver...'
    & 'Display Driver Uninstaller.exe' -Silent -NoRestorePoint -PreventWinUpdate -CleanNvidia | Out-Null
    bcdedit /deletevalue safeboot
    Set-RunOnce
    Set-ItemProperty -Path $ScriptKey -Name UninstallComplete -Value 1
    & shutdown /r /t 0
    Exit
}

#######################
###   Main Script   ###
###############################################################################

# Request (via UAC) to elevate permissions
if (!
    # Current role
    (New-Object Security.Principal.WindowsPrincipal(
        [Security.Principal.WindowsIdentity]::GetCurrent()
    # Is admin?
    )).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
) {
    # Elevate script and exit current non-elevated runtime
    Start-Process `
        -FilePath 'powershell' `
        -ArgumentList (
            #flatten to single array
            '-File', $MyInvocation.MyCommand.Source, $args `
            | %{ $_ }
        ) `
        -Verb RunAs
    exit
}

# Create the script registry key
$ScriptKey = "HKCU:\SOFTWARE\DDUScript"
if (! (Get-Item -Path $ScriptKey)) {
    New-Item -Path $ScriptKey
}

# If booted in Safe Mode, run DDU, else determine script stage and handle appropriately
if (! ([string]::IsNullOrEmpty($env:SAFEBOOT_OPTION))) {
    choco uninstall -y nvidia-display-driver
    Uninstall-DisplayDriver
} else {
    if (Get-ItemProperty -Path $ScriptKey -Name UninstallComplete) {
        Write-Host 'Installing Nvidia driver...'
        choco install -y nvidia-display-driver
        Remove-ItemProperty -Path $ScriptKey -Name UninstallComplete
        Read-Host -Prompt 'Driver update complete! Press any key to exit...'
        Exit
    } else {
        Write-Host 'Installing DDU...'
        choco install -y ddu

        $msg = 'Do you want to reboot your system and upgrade the Nvidia driver? [Y/N]'
        $response = Read-Host -Prompt $msg
        if ($response -like '[Yy]*') {
            # Reboot into Safe Mode with networking
            Write-Host 'Rebooting machine to Safe Mode in 5 seconds...'
            bcdedit /set safeboot minimal | Out-Null
            Set-RunOnce SafeMode
            Start-Sleep -Seconds 5
            Restart-Computer
        } else {
            Write-Host "You chose 'No'. Exiting..."
            Start-Sleep -Seconds 5
            Exit
        }
    }
}
