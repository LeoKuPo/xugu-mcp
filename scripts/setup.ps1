# XuguDB MCP Server - Environment Setup Script for Windows
# This script checks and configures the development environment automatically.
# Run: .\scripts\setup.ps1

param(
    [switch]$SkipTests = $false
)

# Error handling
$ErrorActionPreference = "Stop"

# Project root directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Required versions
$PYTHON_REQUIRED_MAJOR = 3
$PYTHON_REQUIRED_MINOR = 11
$UV_MIN_VERSION = "0.1.0"

# Functions
function Print-Header {
    param([string]$Message)
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Print-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Print-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Print-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Print-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorVariable Err -ErrorAction SilentlyContinue
    return ($null -eq $Err)
}

function Get-PythonVersion {
    if (Test-CommandExists python) {
        $versionOutput = python --version 2>&1
        if ($versionOutput -match "Python (\d+)\.(\d+)\.(\d+)") {
            return "$($Matches[1]).$($Matches[2]).$($Matches[3])"
        }
    }
    if (Test-CommandExists python3) {
        $versionOutput = python3 --version 2>&1
        if ($versionOutput -match "Python (\d+)\.(\d+)\.(\d+)") {
            return "$($Matches[1]).$($Matches[2]).$($Matches[3])"
        }
    }
    return ""
}

function Test-PythonVersion {
    param([string]$Version)

    if ([string]::IsNullOrEmpty($Version)) {
        return $false
    }

    if ($Version -match "^(\d+)\.(\d+)\.") {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]

        return ($major -eq $PYTHON_REQUIRED_MAJOR -and $minor -eq $PYTHON_REQUIRED_MINOR)
    }

    return $false
}

function Test-UvInstalled {
    if (Test-CommandExists uv) {
        $version = uv --version 2>&1
        Print-Success "uv is installed: $version"
        return $true
    }
    else {
        Print-Warning "uv is not installed"
        return $false
    }
}

function Install-Uv {
    Print-Info "Installing uv..."

    # Download and run uv installer
    $installerUrl = "https://astral.sh/uv/install.ps1"
    $installerPath = "$env:TEMP\uv-installer.ps1"

    try {
        Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
        & $installerPath

        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

        # Check if installation succeeded
        if (Test-CommandExists uv) {
            Print-Success "uv installed: $(uv --version)"
        }
        else {
            Print-Warning "uv installed but not in PATH. Please restart your terminal."
            Print-Info "To add uv to PATH manually, add: $env:USERPROFILE\.local\bin"
        }
    }
    catch {
        Print-Error "Failed to install uv: $_"
        Print-Info "Please install uv manually from: https://github.com/astral-sh/uv"
        exit 1
    }
    finally {
        if (Test-Path $installerPath) {
            Remove-Item $installerPath -Force
        }
    }
}

function Install-Python311 {
    Print-Info "Installing Python ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}.x via uv..."

    try {
        uv python install "${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}"

        # Verify installation
        $pythonList = uv python list 2>&1
        if ($pythonList -match "${PYTHON_REQUIRED_MAJOR}\.${PYTHON_REQUIRED_MINOR}") {
            Print-Success "Python ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}.x installed"
            return $true
        }
        else {
            Print-Error "Failed to verify Python installation"
            return $false
        }
    }
    catch {
        Print-Error "Failed to install Python: $_"
        Print-Info "You can install Python 3.11 manually from: https://www.python.org/downloads/"
        return $false
    }
}

function Setup-Venv {
    Print-Info "Setting up virtual environment..."

    Push-Location $ProjectRoot

    try {
        if (Test-Path ".venv") {
            Print-Info "Virtual environment already exists"
        }
        else {
            Print-Info "Creating virtual environment with Python ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}..."
            uv venv --python "${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}"
            Print-Success "Virtual environment created"
        }
    }
    finally {
        Pop-Location
    }
}

function Install-Dependencies {
    Print-Info "Installing dependencies..."

    Push-Location $ProjectRoot

    try {
        uv sync
        Print-Success "Dependencies installed"
    }
    finally {
        Pop-Location
    }
}

function Test-Installation {
    Print-Header "Verifying Installation"

    Push-Location $ProjectRoot

    try {
        # Check if virtual environment exists
        if (!(Test-Path ".venv")) {
            Print-Error "Virtual environment not found"
            return $false
        }

        # Check Python version in venv
        $venvPython = ".venv\Scripts\python.exe"
        if (Test-Path $venvPython) {
            $venvVersion = & $venvPython --version 2>&1
            if ($venvVersion -match "Python (\d+\.\d+\.\d+)") {
                $versionStr = $Matches[1]
                if (Test-PythonVersion -Version $versionStr) {
                    Print-Success "Virtual environment Python: $versionStr"
                }
                else {
                    Print-Warning "Virtual environment Python: $versionStr (may not be optimal)"
                }
            }
        }

        # Check if uv is available
        if (Test-CommandExists uv) {
            Print-Success "uv is available"
        }
        else {
            Print-Warning "uv not found in PATH"
        }

        return $true
    }
    finally {
        Pop-Location
    }
}

# Main setup process
function Main {
    Print-Header "XuguDB MCP Server - Environment Setup"

    Push-Location $ProjectRoot

    try {
        # Step 1: Check uv
        Print-Header "Step 1: Checking uv"
        if (!(Test-UvInstalled)) {
            Install-Uv
        }

        # Step 2: Check Python version
        Print-Header "Step 2: Checking Python Version"

        # Check if uv can find Python 3.11
        $uvPythonList = $null
        try {
            $uvPythonList = uv python list 2>&1
        }
        catch {
            # uv python list might fail if no python installed
        }

        if ($null -ne $uvPythonList -and $uvPythonList -match "${PYTHON_REQUIRED_MAJOR}\.${PYTHON_REQUIRED_MINOR}") {
            Print-Success "Python ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}.x found via uv"
        }
        else {
            Print-Warning "Python ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}.x not found via uv"

            # Check system Python as fallback
            $systemPython = Get-PythonVersion
            if ([string]::IsNullOrEmpty($systemPython)) {
                Print-Warning "No Python found on system"
            }
            else {
                Print-Info "System Python: $systemPython"
            }

            Install-Python311
        }

        # Step 3: Setup virtual environment
        Print-Header "Step 3: Setting Up Virtual Environment"
        Setup-Venv

        # Step 4: Install dependencies
        Print-Header "Step 4: Installing Dependencies"
        Install-Dependencies

        # Step 5: Verify
        Test-Installation

        # Final message
        Print-Header "Setup Complete!"
        Print-Success "Environment is ready!"
        Write-Host ""
        Print-Info "To activate the virtual environment, run:"
        Write-Host "  .venv\Scripts\Activate.ps1" -ForegroundColor Yellow
        Write-Host ""
        Print-Info "To start the MCP server, run:"
        Write-Host "  python main.py" -ForegroundColor Yellow
        Write-Host "  mcp dev ." -ForegroundColor Yellow
        Write-Host ""
    }
    finally {
        Pop-Location
    }
}

# Run main
Main
