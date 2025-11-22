# Install RustDesk Client on Windows
# RustDesk is an open-source remote desktop alternative to RDP
# Supports custom relay servers for secure connections
# Run as Administrator for system-wide installation

param(
    [string]$Version = "latest",
    [string]$RelayServer = "",
    [string]$ApiServer = "",
    [string]$Key = "",
    [switch]$InstallService = $true,
    [switch]$StartAfterInstall = $true
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

Write-ColorOutput "`n========================================" "Cyan"
Write-ColorOutput "RustDesk Client Installation Script" "Cyan"
Write-ColorOutput "========================================`n" "Cyan"

# Check if running as administrator for system-wide install
if ($InstallService -and -not (Test-Administrator)) {
    Write-ColorOutput "WARNING: Not running as Administrator" "Yellow"
    Write-ColorOutput "Service installation will be skipped" "Yellow"
    Write-ColorOutput "For full installation, run as Administrator`n" "Yellow"
    $InstallService = $false
    Start-Sleep -Seconds 2
}

# Determine download URL based on version
if ($Version -eq "latest") {
    Write-ColorOutput "Fetching latest RustDesk version..." "Yellow"
    try {
        $apiUrl = "https://api.github.com/repos/rustdesk/rustdesk/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -Method Get
        $Version = $release.tag_name
        Write-ColorOutput "Latest version: $Version" "Green"
    } catch {
        Write-ColorOutput "ERROR: Failed to fetch latest version" "Red"
        Write-ColorOutput "Error: $_" "Red"
        exit 1
    }
} else {
    Write-ColorOutput "Using specified version: $Version" "Green"
}

# Construct download URL for Windows installer
$downloadUrl = "https://github.com/rustdesk/rustdesk/releases/download/$Version/rustdesk-$Version-x86_64.exe"
$downloadPath = "$env:TEMP\rustdesk-installer.exe"

Write-ColorOutput "`nDownloading RustDesk installer..." "Yellow"
Write-ColorOutput "URL: $downloadUrl" "Gray"

try {
    # Download with progress
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -UseBasicParsing
    $ProgressPreference = 'Continue'
    Write-ColorOutput "Download completed successfully!" "Green"
} catch {
    Write-ColorOutput "ERROR: Failed to download RustDesk" "Red"
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

# Install RustDesk
Write-ColorOutput "`nInstalling RustDesk..." "Yellow"

$installArgs = @("--silent")

if ($InstallService) {
    $installArgs += "--install-service"
}

try {
    $process = Start-Process -FilePath $downloadPath -ArgumentList $installArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-ColorOutput "RustDesk installed successfully!" "Green"
    } else {
        Write-ColorOutput "WARNING: Installation completed with exit code $($process.ExitCode)" "Yellow"
    }
} catch {
    Write-ColorOutput "ERROR: Failed to install RustDesk" "Red"
    Write-ColorOutput "Error: $_" "Red"
    exit 1
} finally {
    # Clean up installer
    if (Test-Path $downloadPath) {
        Remove-Item $downloadPath -Force
        Write-ColorOutput "Cleaned up installer file" "Green"
    }
}

# Wait for installation to complete
Start-Sleep -Seconds 2

# Configure custom relay server if provided
if ($RelayServer -or $ApiServer -or $Key) {
    Write-ColorOutput "`nConfiguring custom relay server..." "Yellow"
    
    # RustDesk config file location
    $configPath = "$env:APPDATA\RustDesk\config\RustDesk2.toml"
    $configDir = Split-Path -Parent $configPath
    
    # Ensure config directory exists
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    # Build configuration
    $config = ""
    
    if ($RelayServer) {
        Write-ColorOutput "Setting relay server: $RelayServer" "Green"
        $config += "relay-server = '$RelayServer'`n"
    }
    
    if ($ApiServer) {
        Write-ColorOutput "Setting API server: $ApiServer" "Green"
        $config += "api-server = '$ApiServer'`n"
    }
    
    if ($Key) {
        Write-ColorOutput "Setting server key" "Green"
        $config += "key = '$Key'`n"
    }
    
    # Write or append to config file
    if (Test-Path $configPath) {
        # Backup existing config
        $backupPath = "$configPath.backup"
        Copy-Item $configPath $backupPath -Force
        Write-ColorOutput "Backed up existing config to $backupPath" "Gray"
    }
    
    try {
        Add-Content -Path $configPath -Value $config -Encoding UTF8
        Write-ColorOutput "Configuration saved successfully!" "Green"
    } catch {
        Write-ColorOutput "WARNING: Failed to write configuration" "Yellow"
        Write-ColorOutput "Error: $_" "Yellow"
        Write-ColorOutput "You may need to configure the relay server manually" "Yellow"
    }
}

# Start RustDesk if requested
if ($StartAfterInstall) {
    Write-ColorOutput "`nStarting RustDesk..." "Yellow"
    Start-Sleep -Seconds 1
    
    try {
        $rustdeskPath = "C:\Program Files\RustDesk\rustdesk.exe"
        if (Test-Path $rustdeskPath) {
            Start-Process $rustdeskPath
            Write-ColorOutput "RustDesk started successfully!" "Green"
        } else {
            # Try alternate location
            $rustdeskPath = "$env:ProgramFiles\RustDesk\rustdesk.exe"
            if (Test-Path $rustdeskPath) {
                Start-Process $rustdeskPath
                Write-ColorOutput "RustDesk started successfully!" "Green"
            } else {
                Write-ColorOutput "Warning: Could not find RustDesk executable" "Yellow"
                Write-ColorOutput "You may need to start it manually" "Yellow"
            }
        }
    } catch {
        Write-ColorOutput "Warning: Could not start RustDesk automatically" "Yellow"
        Write-ColorOutput "Please start it manually from the Start menu" "Yellow"
    }
}

Write-ColorOutput "`n========================================" "Cyan"
Write-ColorOutput "Installation Complete!" "Cyan"
Write-ColorOutput "========================================`n" "Cyan"

Write-ColorOutput "RustDesk Information:" "Cyan"
Write-ColorOutput "- RustDesk is now installed on your system" "White"
Write-ColorOutput "- You can find it in the Start menu" "White"

if ($InstallService) {
    Write-ColorOutput "- Service is installed and will start automatically" "White"
}

if ($RelayServer) {
    Write-ColorOutput "`nCustom Relay Server:" "Cyan"
    Write-ColorOutput "- Relay: $RelayServer" "White"
    if ($ApiServer) {
        Write-ColorOutput "- API: $ApiServer" "White"
    }
    Write-ColorOutput "- Your RustDesk ID will be shown when you start the application" "White"
}

Write-ColorOutput "`nNext Steps:" "Cyan"
Write-ColorOutput "1. Launch RustDesk from the Start menu (if not auto-started)" "White"
Write-ColorOutput "2. Note your RustDesk ID from the main window" "White"
Write-ColorOutput "3. Share your ID with others to allow remote connections" "White"
Write-ColorOutput "4. Set a password for secure unattended access (optional)" "White"

if (-not $RelayServer) {
    Write-ColorOutput "`nCustom Relay Server Setup:" "Cyan"
    Write-ColorOutput "To configure a custom relay server later, you can:" "White"
    Write-ColorOutput "1. Run this script again with -RelayServer parameter" "White"
    Write-ColorOutput "2. Or configure manually in RustDesk settings`n" "White"
    Write-ColorOutput "Example: .\install-rustdesk.ps1 -RelayServer 'your-server.com' -Key 'your-key'" "Gray"
}

Write-ColorOutput "`nRustDesk vs RDP:" "Cyan"
Write-ColorOutput "- RustDesk works over the internet (NAT traversal)" "White"
Write-ColorOutput "- Custom relay servers for privacy and security" "White"
Write-ColorOutput "- Cross-platform (Windows, macOS, Linux, iOS, Android)" "White"
Write-ColorOutput "- Open-source and free" "White"
Write-ColorOutput "- Alternative to TeamViewer, AnyDesk, and traditional RDP`n" "White"
