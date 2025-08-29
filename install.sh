#!/bin/bash

# DevSetup Installation Script for macOS/Linux
# This script detects the platform and ensures PowerShell is available
# Supported platforms: macOS (with Homebrew), Ubuntu Linux (with apt)

set -e  # Exit on any error

echo "DevSetup Installation Script"
echo "============================"

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_PS1="$SCRIPT_DIR/install.ps1"

echo "Script directory: $SCRIPT_DIR"

# Verify the install.ps1 file exists
if [ ! -f "$INSTALL_PS1" ]; then
    echo "ERROR: install.ps1 not found at: $INSTALL_PS1"
    echo "Please ensure you're running this script from the DevSetup directory."
    exit 1
fi

# Detect the platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo "macOS"
            ;;
        Linux*)
            echo "Linux"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

# Check if PowerShell is available
check_powershell() {
    if command -v pwsh >/dev/null 2>&1; then
        echo "PowerShell Core (pwsh) found: $(which pwsh)"
        return 0
    elif command -v powershell >/dev/null 2>&1; then
        echo "PowerShell found: $(which powershell)"
        return 0
    else
        return 1
    fi
}

# Install PowerShell on macOS using Homebrew
install_powershell_macos() {
    echo "Checking for Homebrew..."
    
    if ! command -v brew >/dev/null 2>&1; then
        echo "Homebrew not found. Installing Homebrew..."
        echo "This will require administrator privileges."
        
        # Install Homebrew
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for this session
        if [[ -f "/opt/homebrew/bin/brew" ]]; then
            # Apple Silicon Mac
            export PATH="/opt/homebrew/bin:$PATH"
        elif [[ -f "/usr/local/bin/brew" ]]; then
            # Intel Mac
            export PATH="/usr/local/bin:$PATH"
        fi
        
        # Verify Homebrew installation
        if ! command -v brew >/dev/null 2>&1; then
            echo "ERROR: Failed to install or configure Homebrew."
            echo "Please install Homebrew manually from https://brew.sh/"
            exit 1
        fi
        
        echo "Homebrew installed successfully!"
    else
        echo "Homebrew found: $(which brew)"
    fi
    
    echo "Installing PowerShell using Homebrew..."
    brew install --cask powershell
    
    # Verify PowerShell installation
    if ! check_powershell; then
        echo "ERROR: PowerShell installation failed."
        echo "Please try installing PowerShell manually:"
        echo "  brew install --cask powershell"
        exit 1
    fi
    
    echo "PowerShell installed successfully!"
}

# Install PowerShell on Ubuntu using apt
install_powershell_ubuntu() {
    echo "Installing PowerShell on Ubuntu..."
    echo "This will require administrator privileges (sudo)."
    
    # Update the list of packages
    echo "Updating package list..."
    sudo apt-get update
    
    # Install pre-requisite packages
    echo "Installing prerequisites..."
    sudo apt-get install -y wget apt-transport-https software-properties-common
    
    # Get the version of Ubuntu
    source /etc/os-release
    echo "Ubuntu version: $VERSION_ID"
    
    # Download the Microsoft repository keys
    echo "Downloading Microsoft repository keys..."
    wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
    
    # Register the Microsoft repository keys
    echo "Registering Microsoft repository..."
    sudo dpkg -i packages-microsoft-prod.deb
    
    # Delete the Microsoft repository keys file
    rm packages-microsoft-prod.deb
    
    # Update the list of packages after we added packages.microsoft.com
    echo "Updating package list with Microsoft repository..."
    sudo apt-get update
    
    # Install PowerShell
    echo "Installing PowerShell..."
    sudo apt-get install -y powershell
    
    # Verify PowerShell installation
    if ! check_powershell; then
        echo "ERROR: PowerShell installation failed."
        echo "Please try installing PowerShell manually:"
        echo "  sudo apt-get install -y powershell"
        echo ""
        echo "Or visit: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux"
        exit 1
    fi
    
    echo "PowerShell installed successfully!"
}

# Run the PowerShell installer
run_powershell_installer() {
    local ps_command=""
    
    if command -v pwsh >/dev/null 2>&1; then
        ps_command="pwsh"
    elif command -v powershell >/dev/null 2>&1; then
        ps_command="powershell"
    else
        echo "ERROR: No PowerShell found after installation attempt."
        exit 1
    fi
    
    echo "Running PowerShell installer..."
    echo "Command: $ps_command -NoProfile -ExecutionPolicy Bypass -File \"$INSTALL_PS1\""
    
    "$ps_command" -NoProfile -ExecutionPolicy Bypass -File "$INSTALL_PS1"
}

# Main execution flow
PLATFORM=$(detect_platform)
echo "Detected platform: $PLATFORM"

case "$PLATFORM" in
    "macOS")
        echo "macOS detected - checking PowerShell availability..."
        
        if check_powershell; then
            echo "PowerShell is already available."
        else
            echo "PowerShell not found. Installing via Homebrew..."
            install_powershell_macos
        fi
        
        run_powershell_installer
        ;;
        
    "Linux")
        echo "Linux detected - checking for Ubuntu..."
        
        # Check if this is Ubuntu
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            if [[ "$ID" == "ubuntu" ]]; then
                echo "Ubuntu $VERSION_ID detected - proceeding with PowerShell installation..."
                
                if check_powershell; then
                    echo "PowerShell is already available."
                else
                    echo "PowerShell not found. Installing via apt..."
                    install_powershell_ubuntu
                fi
                
                run_powershell_installer
            else
                echo "WARNING: Limited Linux support - only Ubuntu is currently supported."
                echo ""
                echo "Detected distribution: $ID"
                echo "DevSetup currently supports:"
                echo "  - Windows (native)"
                echo "  - macOS (with Homebrew)"
                echo "  - Ubuntu Linux (with apt)"
                echo ""
                echo "For other Linux distributions:"
                echo "1. Install PowerShell manually for your distribution"
                echo "2. Run: pwsh -NoProfile -ExecutionPolicy Bypass -File install.ps1"
                echo "3. Check the project repository for updates"
                echo ""
                echo "For more information, visit:"
                echo "  https://github.com/Joshua-Wilson_questsw/devsetup"
                echo ""
                exit 1
            fi
        else
            echo "WARNING: Cannot determine Linux distribution."
            echo ""
            echo "DevSetup has limited Linux support (Ubuntu only)."
            echo "If you're on Ubuntu, please ensure /etc/os-release exists."
            echo ""
            echo "For manual installation:"
            echo "1. Install PowerShell for your distribution"
            echo "2. Run: pwsh -NoProfile -ExecutionPolicy Bypass -File install.ps1"
            echo ""
            exit 1
        fi
        ;;
        
    *)
        echo "ERROR: Unsupported platform detected."
        echo "DevSetup currently supports:"
        echo "  - Windows (native)"
        echo "  - macOS (with Homebrew)"
        echo "  - Ubuntu Linux (with apt)"
        echo ""
        echo "Your platform: $(uname -a)"
        echo ""
        exit 1
        ;;
esac

echo ""
echo "Installation completed successfully!"
echo "DevSetup is now available on your system."
