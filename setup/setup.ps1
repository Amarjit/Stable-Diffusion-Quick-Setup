# ==============================================================================
# Windows Environment Preparation Script (vFinal-URL-Fix)
# ==============================================================================

# --- Configuration ---
$WslDistroName = "Ubuntu-SD"
$WslInstallDir = "C:\WSL\$WslDistroName"
$DefaultUsername = "sduser"
$DefaultPassword = "docker"

# --- CORRECTED URL AND FILENAME ---
$UbuntuImageURL = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64-root.tar.xz"
$UbuntuImageFile = "jammy-server-cloudimg-amd64-root.tar.xz"
$TempDir = "$env:TEMP\wsl-setup"

# --- Helper Function for Headers ---
function Write-Header($Title) {
    Write-Host "`n"
    Write-Host "======================================================================" -ForegroundColor Green
    Write-Host "  $Title" -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
}

# --- Script Start ---

# 1. Check for Administrator Privileges
Write-Header "Step 1: Checking for Administrator Privileges"
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as an Administrator. Please re-open PowerShell as Administrator and try again."
    pause
    exit
}
Write-Host "✅ Administrator privileges confirmed."

# 2. Check for Docker Desktop
Write-Header "Step 2: Checking for Docker Desktop"
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "‼️ Docker command not found. Docker Desktop is a primary requirement." -ForegroundColor Red
    Write-Host "Please download and install Docker Desktop for Windows from:"
    Write-Host "https://www.docker.com/products/docker-desktop/"
    Write-Host "After installation, start Docker Desktop and then re-run this script."
    Read-Host "Press Enter to exit..."
    exit
}
Write-Host "✅ Docker command found. Docker Desktop is installed."

# 3. Check for and Install Core WSL & Virtual Machine Features
Write-Header "Step 3: Checking Core WSL Features"
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
if ($wslFeature.State -ne "Enabled") {
    Write-Host "The WSL optional feature is not installed. Installing..." -ForegroundColor Yellow
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    Write-Host "‼️ WSL features enabled. A REBOOT IS REQUIRED." -ForegroundColor Yellow
    Write-Host "Please reboot your computer and then re-run this script."
    pause
    exit
}
Write-Host "✅ Core WSL feature is enabled."

# 4. Check for and create the specific "Ubuntu-SD" instance
Write-Header "Step 4: Checking for '$WslDistroName' WSL Instance"
$wslList = wsl --list --quiet
if ($wslList -contains $WslDistroName) {
    Write-Host "✅ WSL instance '$WslDistroName' already exists. Skipping installation."
} else {
    Write-Host "'$WslDistroName' not found. Starting installation process..." -ForegroundColor Yellow
    
    # Create directories
    New-Item -Path $WslInstallDir -ItemType Directory -Force | Out-Null
    New-Item -Path $TempDir -ItemType Directory -Force | Out-Null
    $ubuntuImagePath = Join-Path $TempDir $UbuntuImageFile

    # Download Ubuntu Image
    Write-Host "Downloading Ubuntu 22.04 WSL image..."
    try {
        Invoke-WebRequest -Uri $UbuntuImageURL -OutFile $ubuntuImagePath
    } catch {
        Write-Error "Failed to download Ubuntu image. Error: $_"; pause; exit
    }

    # Import the image into WSL
    Write-Host "Importing image as '$WslDistroName'..."
    wsl --import $WslDistroName $WslInstallDir $ubuntuImagePath --version 2
    
    # Automatic User Creation
    Write-Host "Setting up default user..."
    wsl -d $WslDistroName --exec useradd -m -s /bin/bash -G sudo $DefaultUsername
    $passwordCommand = "$DefaultUsername`:$DefaultPassword"
    echo $passwordCommand | wsl -d $WslDistroName --exec chpasswd
    
    # Set the new user as the default for this instance
    $wslConfContent = "[user]`ndefault=$DefaultUsername"
    $wslConfContent | Out-File -FilePath \\wsl$\$WslDistroName\etc\wsl.conf -Encoding ASCII
    
    Write-Host "✅ Default user created successfully!" -ForegroundColor Green
    Write-Host "   Username: $DefaultUsername" -ForegroundColor Yellow
    Write-Host "   Password: $DefaultPassword" -ForegroundColor Yellow
    
    # Clean up downloaded tarball
    Remove-Item -Path $TempDir -Recurse -Force
}

# --- Final Instructions ---
Write-Header "✅ System Preparation Complete"
Write-Host "Your Windows system is now prepared." -ForegroundColor Cyan
Write-Host "➡️ Your final manual step is to ensure WSL Integration is enabled for '$WslDistroName' in:"
Write-Host "   Docker Desktop Settings -> Resources -> WSL Integration"
