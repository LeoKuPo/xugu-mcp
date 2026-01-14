"""
XuguDB MCP Server - One-click Environment Setup

This module provides automated environment setup for pip-installed packages.
It checks Python version, installs uv if needed, installs correct Python version,
and guides users through the setup process.

Usage:
    xugu-mcp-setup
    python -m xugu_mcp.setup_installer
"""
from __future__ import annotations

import os
import subprocess
import sys
import platform
import shutil
from typing import Tuple, List

# ANSI color codes
class Colors:
    """ANSI color codes for terminal output."""
    CYAN = "\033[96m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    BLUE = "\033[94m"
    BOLD = "\033[1m"
    END = "\033[0m"

# Reset colors for Windows
if sys.platform == "win32":
    try:
        import ctypes
        kernel32 = ctypes.windll.kernel32
        kernel32.SetConsoleMode(kernel32.GetStdHandle(-11), 7)
    except:
        pass


def c_print(color: str, text: str) -> None:
    """Print colored text."""
    print(f"{color}{text}{Colors.END}")


def print_header(text: str) -> None:
    """Print a header."""
    c_print(Colors.CYAN, "=" * 50)
    c_print(Colors.CYAN, text)
    c_print(Colors.CYAN, "=" * 50)


def print_success(text: str) -> None:
    """Print success message."""
    c_print(Colors.GREEN, f"✅ {text}")


def print_warning(text: str) -> None:
    """Print warning message."""
    c_print(Colors.YELLOW, f"⚠️  {text}")


def print_error(text: str) -> None:
    """Print error message."""
    c_print(Colors.RED, f"❌ {text}")


def print_info(text: str) -> None:
    """Print info message."""
    c_print(Colors.BLUE, f"ℹ️  {text}")


# Python version requirements
PYTHON_REQUIRED_MIN = (3, 6)
PYTHON_REQUIRED_MAX = (3, 11)
PYTHON_RECOMMENDED = (3, 11)


def get_python_version() -> Tuple[int, int, int]:
    """Get current Python version as tuple."""
    return (sys.version_info.major, sys.version_info.minor, sys.version_info.micro)


def check_python_version() -> Tuple[bool, str]:
    """Check if Python version is in supported range.

    Returns:
        tuple[bool, str]: (is_valid, message)
    """
    version = get_python_version()
    version_str = f"Python {version[0]}.{version[1]}.{version[2]}"

    if PYTHON_REQUIRED_MIN <= (version[0], version[1]) <= PYTHON_REQUIRED_MAX:
        if (version[0], version[1]) == PYTHON_RECOMMENDED:
            return True, f"{version_str} (Recommended)"
        return True, version_str

    if version > (PYTHON_REQUIRED_MAX[0], PYTHON_REQUIRED_MAX[1]):
        return False, f"{version_str} is NOT supported. This project requires Python {PYTHON_REQUIRED_MIN[0]}.{PYTHON_REQUIRED_MIN[1]}-{PYTHON_REQUIRED_MAX[0]}.{PYTHON_REQUIRED_MAX[1]}. Your version is too new."

    return False, f"{version_str} is NOT supported. This project requires Python {PYTHON_REQUIRED_MIN[0]}.{PYTHON_REQUIRED_MIN[1]}-{PYTHON_REQUIRED_MAX[0]}.{PYTHON_REQUIRED_MAX[1]}."


def check_uv_installed() -> Tuple[bool, str]:
    """Check if uv package manager is installed.

    Returns:
        tuple[bool, str]: (is_valid, message)
    """
    uv_path = shutil.which("uv")
    if uv_path:
        try:
            result = subprocess.run([uv_path, "--version"], capture_output=True, text=True)
            version = result.stdout.strip() if result.returncode == 0 else "unknown"
            return True, f"uv {version} at {uv_path}"
        except:
            return True, f"uv at {uv_path}"
    return False, "uv is not installed or not in PATH"


def install_uv() -> bool:
    """Install uv package manager.

    Returns:
        bool: True if successful, False otherwise
    """
    print_info("Installing uv package manager...")

    system = platform.system().lower()
    try:
        if system == "windows":
            print_info("Run this in PowerShell:")
            c_print(Colors.YELLOW, "  irm https://astral.sh/uv/install.ps1 | iex")
            print_info("Or download from: https://github.com/astral-sh/uv#installing-uv")
        elif system == "darwin":
            print_info("Run one of these commands:")
            c_print(Colors.YELLOW, "  curl -LsSf https://astral.sh/uv/install.sh | sh")
            c_print(Colors.YELLOW, "  brew install uv")
        else:  # linux
            c_print(Colors.YELLOW, "  curl -LsSf https://astral.sh/uv/install.sh | sh")

        print_info("After installing uv, run this command again:")
        c_print(Colors.BOLD, "  xugu-mcp-setup")
        return False
    except Exception as e:
        print_error(f"Failed to install uv: {e}")
        return False


def install_python_via_uv() -> bool:
    """Install Python 3.11 using uv.

    Returns:
        bool: True if successful, False otherwise
    """
    if not shutil.which("uv"):
        print_error("uv is not installed. Please install uv first.")
        return False

    print_info(f"Installing Python {PYTHON_RECOMMENDED[0]}.{PYTHON_RECOMMENDED[1]} via uv...")
    try:
        result = subprocess.run(
            ["uv", "python", "install", f"{PYTHON_RECOMMENDED[0]}.{PYTHON_RECOMMENDED[1]}"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            print_success(f"Python {PYTHON_RECOMMENDED[0]}.{PYTHON_RECOMMENDED[1]} installed via uv")
            return True
        else:
            print_error(f"Failed to install Python: {result.stderr}")
            return False
    except Exception as e:
        print_error(f"Failed to install Python: {e}")
        return False


def get_uv_python_command() -> str:
    """Get the command to run Python via uv.

    Returns:
        str: Command to run Python 3.11 via uv
    """
    return f"uv run --python {PYTHON_RECOMMENDED[0]}.{PYTHON_RECOMMENDED[1]}"


def print_python_install_instructions() -> None:
    """Print instructions for installing correct Python version."""
    system = platform.system().lower()

    print_header("How to Install Python 3.11")

    if system == "windows":
        print_info("Option 1: Using uv (Recommended)")
        c_print(Colors.YELLOW, "  1. Install uv:")
        c_print(Colors.YELLOW, "     irm https://astral.sh/uv/install.ps1 | iex")
        c_print(Colors.YELLOW, "  2. Install Python:")
        c_print(Colors.YELLOW, "     uv python install 3.11")
        c_print(Colors.YELLOW, "  3. Use this project:")
        c_print(Colors.YELLOW, "     uv run --python 3.11 xugu-mcp")
        print()

        print_info("Option 2: Using pyenv-win")
        c_print(Colors.YELLOW, "  1. Install pyenv-win:")
        c_print(Colors.YELLOW, "     Invoke-WebRequest -Uri https://raw.githubusercontent.com/pyenv-win/pyenv-win/master/pyenv-win/install-pyenv-win.ps1 -OutFile ./install-pyenv-win.ps1; &./install-pyenv-win.ps1")
        c_print(Colors.YELLOW, "  2. Install Python:")
        c_print(Colors.YELLOW, "     pyenv install 3.11.9")
        c_print(Colors.YELLOW, "     pyenv global 3.11.9")
        print()

        print_info("Option 3: Manual download")
        c_print(Colors.YELLOW, "  Download from: https://www.python.org/downloads/release/python-3119/")
        c_print(Colors.YELLOW, "  Install and add to PATH")

    elif system == "darwin":
        print_info("Option 1: Using uv (Recommended)")
        c_print(Colors.YELLOW, "  1. Install uv:")
        c_print(Colors.YELLOW, "     curl -LsSf https://astral.sh/uv/install.sh | sh")
        c_print(Colors.YELLOW, "  2. Install Python:")
        c_print(Colors.YELLOW, "     uv python install 3.11")
        c_print(Colors.YELLOW, "  3. Use this project:")
        c_print(Colors.YELLOW, "     uv run --python 3.11 xugu-mcp")
        print()

        print_info("Option 2: Using pyenv (Recommended)")
        c_print(Colors.YELLOW, "  1. Install pyenv:")
        c_print(Colors.YELLOW, "     brew install pyenv")
        c_print(Colors.YELLOW, "  2. Install Python:")
        c_print(Colors.YELLOW, "     pyenv install 3.11.9")
        c_print(Colors.YELLOW, "     pyenv local 3.11.9")
        print()

        print_info("Option 3: Using conda")
        c_print(Colors.YELLOW, "  conda create -n xugu-mcp python=3.11")
        c_print(Colors.YELLOW, "  conda activate xugu-mcp")

    else:  # linux
        print_info("Option 1: Using uv (Recommended)")
        c_print(Colors.YELLOW, "  1. Install uv:")
        c_print(Colors.YELLOW, "     curl -LsSf https://astral.sh/uv/install.sh | sh")
        c_print(Colors.YELLOW, "  2. Install Python:")
        c_print(Colors.YELLOW, "     uv python install 3.11")
        c_print(Colors.YELLOW, "  3. Use this project:")
        c_print(Colors.YELLOW, "     uv run --python 3.11 xugu-mcp")
        print()

        print_info("Option 2: Using pyenv (Recommended)")
        c_print(Colors.YELLOW, "  1. Install pyenv:")
        c_print(Colors.YELLOW, "     curl https://pyenv.run | bash")
        c_print(Colors.YELLOW, "  2. Install Python:")
        c_print(Colors.YELLOW, "     pyenv install 3.11.9")
        c_print(Colors.YELLOW, "     pyenv local 3.11.9")
        print()

        print_info("Option 3: Using conda")
        c_print(Colors.YELLOW, "  conda create -n xugu-mcp python=3.11")
        c_print(Colors.YELLOW, "  conda activate xugu-mcp")

    print()


def main() -> int:
    """Main setup function.

    Returns:
        int: Exit code (0 for success, 1 for failure)
    """
    print_header("XuguDB MCP Server - Environment Setup")

    # Step 1: Check Python version
    print_header("Step 1: Checking Python Version")
    python_valid, python_msg = check_python_version()
    print(f"Current: {python_msg}")

    if python_valid:
        version = get_python_version()
        if (version[0], version[1]) == PYTHON_RECOMMENDED:
            print_success("Python version is optimal!")
        else:
            print_warning(f"Python version is supported, but {PYTHON_RECOMMENDED[0]}.{PYTHON_RECOMMENDED[1]} is recommended.")
    else:
        print_error("Python version is NOT supported!")
        print()
        print_python_install_instructions()
        return 1

    # Step 2: Check uv installation
    print_header("Step 2: Checking uv Package Manager")
    uv_valid, uv_msg = check_uv_installed()
    print(uv_msg)

    if not uv_valid:
        print_warning("uv is recommended for better Python version management")
        print()
        install_uv()
        return 1

    # Step 3: Environment is ready
    print_header("Setup Complete!")
    print_success("Your environment is ready!")
    print()
    print_info("You can now use XuguDB MCP Server:")
    print()
    c_print(Colors.GREEN, "  Start MCP server (stdio mode):")
    c_print(Colors.YELLOW, "    xugu-mcp")
    print()
    c_print(Colors.GREEN, "  Start HTTP server:")
    c_print(Colors.YELLOW, "    xugu-mcp-http")
    print()

    # Additional info if Python is not 3.11
    version = get_python_version()
    if (version[0], version[1]) != PYTHON_RECOMMENDED:
        print_warning("For optimal compatibility, consider using Python 3.11:")
        c_print(Colors.YELLOW, f"  uv python install {PYTHON_RECOMMENDED[0]}.{PYTHON_RECOMMENDED[1]}")
        c_print(Colors.YELLOW, f"  {get_uv_python_command()} xugu-mcp")
        print()

    return 0


def cli_main() -> None:
    """CLI entry point for xugu-mcp-setup command."""
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print()
        print_info("Setup cancelled by user.")
        sys.exit(1)
    except Exception as e:
        print_error(f"An error occurred: {e}")
        sys.exit(1)


if __name__ == "__main__":
    cli_main()
