# Install Docker Desktop on Windows
# This script downloads and installs Docker Desktop with WSL2 backend
# Requires: Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11
# Run as Administrator

param(
    [string]$Version = "latest",
    [switch]$EnableWSL2 = $true,
    [switch]$StartAfterInstall = $true,
    [switch]$SkipPrerequisites = $false
)

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to write colored output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

# Check if running as administrator
if (-not (Test-Administrator)) {
    Write-ColorOutput "ERROR: This script must be run as Administrator!" "Red"
    Write-ColorOutput "Please right-click PowerShell and select 'Run as Administrator'" "Yellow"
    exit 1
}

Write-ColorOutput "`n========================================" "Cyan"
Write-ColorOutput "Docker Desktop Installation Script" "Cyan"
Write-ColorOutput "========================================`n" "Cyan"

# Check Windows version
$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$buildNumber = [int]$osInfo.BuildNumber
$osVersion = $osInfo.Caption

Write-ColorOutput "Detected OS: $osVersion (Build $buildNumber)" "Green"

if ($buildNumber -lt 19041) {
    Write-ColorOutput "ERROR: Docker Desktop requires Windows 10 Build 19041 or higher, or Windows 11" "Red"
    Write-ColorOutput "Your build: $buildNumber" "Yellow"
    exit 1
}

# Check and enable WSL2 if requested
if ($EnableWSL2 -and -not $SkipPrerequisites) {
    Write-ColorOutput "`nChecking WSL2 prerequisites..." "Yellow"
    
    # Enable WSL feature
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    if ($wslFeature.State -ne "Enabled") {
        Write-ColorOutput "Enabling WSL feature..." "Yellow"
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -WarningAction SilentlyContinue | Out-Null
    } else {
        Write-ColorOutput "WSL feature is already enabled" "Green"
    }
    
    # Enable Virtual Machine Platform
    $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    if ($vmFeature.State -ne "Enabled") {
        Write-ColorOutput "Enabling Virtual Machine Platform..." "Yellow"
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -WarningAction SilentlyContinue | Out-Null
    } else {
        Write-ColorOutput "Virtual Machine Platform is already enabled" "Green"
    }
    
    # Update WSL to version 2
    Write-ColorOutput "Updating WSL to version 2..." "Yellow"
    try {
        wsl --set-default-version 2 2>$null | Out-Null
        Write-ColorOutput "WSL2 set as default" "Green"
    } catch {
        Write-ColorOutput "Note: WSL2 update may require a system restart" "Yellow"
    }
}

# Download Docker Desktop
$downloadPath = "$env:TEMP\DockerDesktopInstaller.exe"

if ($Version -eq "latest") {
    $downloadUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    Write-ColorOutput "`nDownloading Docker Desktop (latest version)..." "Yellow"
} else {
    $downloadUrl = "https://desktop.docker.com/win/main/amd64/$Version/Docker%20Desktop%20Installer.exe"
    Write-ColorOutput "`nDownloading Docker Desktop version $Version..." "Yellow"
}

try {
    # Use .NET WebClient for better progress indication
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($downloadUrl, $downloadPath)
    Write-ColorOutput "Download completed successfully!" "Green"
} catch {
    Write-ColorOutput "ERROR: Failed to download Docker Desktop" "Red"
    Write-ColorOutput "Error: $_" "Red"
    Write-ColorOutput "URL: $downloadUrl" "Yellow"
    exit 1
}

# Verify download
if (-not (Test-Path $downloadPath)) {
    Write-ColorOutput "ERROR: Downloaded file not found at $downloadPath" "Red"
    exit 1
}

$fileSize = (Get-Item $downloadPath).Length / 1MB
Write-ColorOutput "Downloaded file size: $([math]::Round($fileSize, 2)) MB" "Green"

# Install Docker Desktop
Write-ColorOutput "`nInstalling Docker Desktop..." "Yellow"
Write-ColorOutput "This may take several minutes. Please wait..." "Yellow"

$installArgs = @(
    "install",
    "--quiet"
)

if ($EnableWSL2) {
    $installArgs += "--backend=wsl-2"
}

try {
    $process = Start-Process -FilePath $downloadPath -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-ColorOutput "`nDocker Desktop installed successfully!" "Green"
    } elseif ($process.ExitCode -eq 3010) {
        Write-ColorOutput "`nDocker Desktop installed successfully (restart required)!" "Green"
    } else {
        Write-ColorOutput "`nERROR: Installation failed with exit code $($process.ExitCode)" "Red"
        exit 1
    }
} catch {
    Write-ColorOutput "ERROR: Failed to install Docker Desktop" "Red"
    Write-ColorOutput "Error: $_" "Red"
    exit 1
} finally {
    # Clean up installer
    if (Test-Path $downloadPath) {
        Remove-Item $downloadPath -Force
        Write-ColorOutput "Cleaned up installer file" "Green"
    }
}

# Start Docker Desktop if requested
if ($StartAfterInstall) {
    Write-ColorOutput "`nStarting Docker Desktop..." "Yellow"
    try {
        $dockerDesktopPath = "C:\Program Files\Docker\Docker\Docker Desktop.exe"
        if (Test-Path $dockerDesktopPath) {
            Start-Process $dockerDesktopPath
            Write-ColorOutput "Docker Desktop started successfully!" "Green"
            Write-ColorOutput "Please wait for Docker to initialize (may take 1-2 minutes)" "Yellow"
        } else {
            Write-ColorOutput "Warning: Could not find Docker Desktop executable" "Yellow"
            Write-ColorOutput "You may need to start it manually from the Start menu" "Yellow"
        }
    } catch {
        Write-ColorOutput "Warning: Could not start Docker Desktop automatically" "Yellow"
        Write-ColorOutput "Please start it manually from the Start menu" "Yellow"
    }
}

Write-ColorOutput "`n========================================" "Cyan"
Write-ColorOutput "Installation Complete!" "Cyan"
Write-ColorOutput "========================================`n" "Cyan"

if ($EnableWSL2) {
    Write-ColorOutput "NOTE: A system restart may be required for WSL2 to work properly" "Yellow"
    Write-ColorOutput "If Docker fails to start, please restart your computer" "Yellow"
}

Write-ColorOutput "`nNext Steps:" "Cyan"
Write-ColorOutput "1. Wait for Docker Desktop to start and complete initialization" "White"
Write-ColorOutput "2. Sign in to Docker Desktop (optional)" "White"
Write-ColorOutput "3. Verify installation by running: docker --version" "White"
Write-ColorOutput "4. Test with: docker run hello-world`n" "White"

# Offer to restart
$restart = Read-Host "Would you like to restart now? (Y/N)"
if ($restart -eq "Y" -or $restart -eq "y") {
    Write-ColorOutput "Restarting system in 10 seconds..." "Yellow"
    shutdown /r /t 10 /c "Restarting to complete Docker Desktop installation"
} else {
    Write-ColorOutput "Please restart manually when convenient" "Yellow"
}
