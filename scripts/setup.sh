#!/bin/bash
# XuguDB MCP Server - Environment Setup Script for Linux/macOS
# This script checks and configures the development environment automatically.

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Required versions
PYTHON_REQUIRED_MAJOR=3
PYTHON_REQUIRED_MINOR=11
UV_MIN_VERSION="0.1.0"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Get Python version
get_python_version() {
    if command_exists python3; then
        python3 --version 2>&1 | awk '{print $2}'
    elif command_exists python; then
        python --version 2>&1 | awk '{print $2}'
    else
        echo ""
    fi
}

# Parse Python version
parse_python_version() {
    local version=$1
    if [[ -z "$version" ]]; then
        echo "0"
        echo "0"
        echo "0"
        return
    fi

    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    local patch=$(echo "$version" | cut -d. -f3 | cut -d' ' -f1)

    echo "$major"
    echo "$minor"
    echo "${patch:-0}"
}

# Check if Python version matches
check_python_version() {
    local version=$1
    read -r major minor patch <<< "$(parse_python_version "$version")"

    if [[ "$major" -eq "$PYTHON_REQUIRED_MAJOR" && "$minor" -eq "$PYTHON_REQUIRED_MINOR" ]]; then
        return 0
    else
        return 1
    fi
}

# Check if uv is installed
check_uv() {
    if command_exists uv; then
        print_success "uv is installed: $(uv --version)"
        return 0
    else
        print_warning "uv is not installed"
        return 1
    fi
}

# Install uv
install_uv() {
    print_info "Installing uv..."

    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install uv
        else
            curl -LsSf https://astral.sh/uv/install.sh | sh
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        print_error "Unsupported OS: $OSTYPE"
        print_info "Please install uv manually from: https://github.com/astral-sh/uv"
        exit 1
    fi

    # Add to PATH if needed
    if ! command_exists uv && [[ -f "$HOME/.local/bin/uv" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi

    if command_exists uv; then
        print_success "uv installed: $(uv --version)"
    else
        print_error "Failed to install uv"
        print_info "Please install manually from: https://github.com/astral-sh/uv"
        exit 1
    fi
}

# Install Python 3.11 using uv
install_python_311() {
    print_info "Installing Python ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}.x via uv..."

    uv python install "${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}"

    if uv python list | grep -q "${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}"; then
        print_success "Python ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}.x installed"
        return 0
    else
        print_error "Failed to install Python ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}.x"
        return 1
    fi
}

# Setup virtual environment
setup_venv() {
    print_info "Setting up virtual environment..."

    cd "$PROJECT_ROOT"

    if [[ -d ".venv" ]]; then
        print_info "Virtual environment already exists"
    else
        print_info "Creating virtual environment with Python ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}..."
        uv venv --python "${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}"
        print_success "Virtual environment created"
    fi
}

# Install dependencies
install_dependencies() {
    print_info "Installing dependencies..."

    cd "$PROJECT_ROOT"

    uv sync

    print_success "Dependencies installed"
}

# Verify installation
verify_installation() {
    print_header "Verifying Installation"

    cd "$PROJECT_ROOT"

    # Check if virtual environment exists
    if [[ ! -d ".venv" ]]; then
        print_error "Virtual environment not found"
        return 1
    fi

    # Check Python version in venv
    local venv_python="$PROJECT_ROOT/.venv/bin/python"
    if [[ -f "$venv_python" ]]; then
        local venv_version=$($venv_python --version 2>&1 | awk '{print $2}')
        if check_python_version "$venv_version"; then
            print_success "Virtual environment Python: $venv_version"
        else
            print_warning "Virtual environment Python: $venv_version (may not be optimal)"
        fi
    fi

    # Check if uv is available
    if command_exists uv; then
        print_success "uv is available"
    else
        print_warning "uv not found in PATH"
    fi

    return 0
}

# Main setup process
main() {
    print_header "XuguDB MCP Server - Environment Setup"

    cd "$PROJECT_ROOT"

    # Step 1: Check uv
    print_header "Step 1: Checking uv"
    if ! check_uv; then
        install_uv
    fi

    # Step 2: Check Python version
    print_header "Step 2: Checking Python Version"

    # First, check if uv can find Python 3.11
    if uv python list &> /dev/null; then
        local available_python=$(uv python list | grep "${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}" | head -n 1)
        if [[ -n "$available_python" ]]; then
            print_success "Python ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}.x found via uv"
        else
            print_warning "Python ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}.x not found via uv"
            install_python_311
        fi
    else
        # Fallback: check system Python
        local system_python=$(get_python_version)
        print_info "System Python: $system_python"

        if check_python_version "$system_python"; then
            print_success "System Python version is compatible"
        else
            print_warning "System Python version is not ${PYTHON_REQUIRED_MAJOR}.${PYTHON_REQUIRED_MINOR}.x"
            install_python_311
        fi
    fi

    # Step 3: Setup virtual environment
    print_header "Step 3: Setting Up Virtual Environment"
    setup_venv

    # Step 4: Install dependencies
    print_header "Step 4: Installing Dependencies"
    install_dependencies

    # Step 5: Verify
    verify_installation

    # Final message
    print_header "Setup Complete!"
    print_success "Environment is ready!"
    echo ""
    print_info "To activate the virtual environment, run:"
    echo -e "  ${YELLOW}source .venv/bin/activate${NC}  # macOS/Linux"
    echo ""
    print_info "To start the MCP server, run:"
    echo -e "  ${YELLOW}python main.py${NC}"
    echo -e "  ${YELLOW}mcp dev .${NC}"
    echo ""
}

# Run main
main
