"""
Environment check module for XuguDB MCP Server.

Performs environment validation checks and provides warnings for LLM.
"""
import sys
import shutil
from typing import NamedTuple

# Python version requirements
PYTHON_REQUIRED_MIN = (3, 6)
PYTHON_REQUIRED_MAX = (3, 11)
PYTHON_RECOMMENDED = (3, 11)


class EnvCheckResult(NamedTuple):
    """Result of environment check."""
    is_valid: bool
    warnings: list[str]
    errors: list[str]


def check_python_version() -> tuple[bool, str]:
    """Check if Python version is in the supported range (3.6-3.11).

    Returns:
        tuple[bool, str]: (is_valid, message)
    """
    version = sys.version_info
    version_str = f"Python {version.major}.{version.minor}.{version.micro}"

    # Check if in supported range
    if PYTHON_REQUIRED_MIN <= (version.major, version.minor) <= PYTHON_REQUIRED_MAX:
        if (version.major, version.minor) == PYTHON_RECOMMENDED:
            return True, f"{version_str} (Recommended)"
        return True, version_str

    # Version is too new
    if (version.major, version.minor) > PYTHON_REQUIRED_MAX:
        return False, (
            f"{version_str} is not supported. This project requires "
            f"Python {PYTHON_REQUIRED_MIN[0]}.{PYTHON_REQUIRED_MIN[1]}-"
            f"{PYTHON_REQUIRED_MAX[0]}.{PYTHON_REQUIRED_MAX[1]}. "
            f"Current version is too new."
        )

    # Version is too old
    return False, (
        f"{version_str} is not supported. This project requires "
        f"Python {PYTHON_REQUIRED_MIN[0]}.{PYTHON_REQUIRED_MIN[1]}-"
        f"{PYTHON_REQUIRED_MAX[0]}.{PYTHON_REQUIRED_MAX[1]}. "
        f"Current version is too old."
    )


def check_uv_installed() -> tuple[bool, str]:
    """Check if uv package manager is installed.

    Returns:
        tuple[bool, str]: (is_valid, message)
    """
    uv_path = shutil.which("uv")
    if uv_path:
        return True, f"uv is installed at {uv_path}"
    return False, "uv package manager is not installed or not in PATH. Please install uv from https://github.com/astral-sh/uv"


def check_environment() -> EnvCheckResult:
    """Perform all environment checks.

    Returns:
        EnvCheckResult: Result of all checks
    """
    warnings: list[str] = []
    errors: list[str] = []

    # Check Python version
    python_valid, python_msg = check_python_version()
    if not python_valid:
        errors.append(python_msg)

    # Check uv installation
    uv_valid, uv_msg = check_uv_installed()
    if not uv_valid:
        warnings.append(uv_msg)

    return EnvCheckResult(
        is_valid=python_valid and uv_valid,
        warnings=warnings,
        errors=errors,
    )


def get_env_warning_for_llm() -> str | None:
    """Get environment warning message for LLM.

    Returns:
        str | None: Warning message if environment has issues, None otherwise
    """
    result = check_environment()

    if result.is_valid:
        return None

    lines = ["⚠️ ENVIRONMENT WARNING:"]
    if result.errors:
        lines.append("")
        lines.append("Errors:")
        for error in result.errors:
            lines.append(f"  - {error}")
    if result.warnings:
        lines.append("")
        lines.append("Warnings:")
        for warning in result.warnings:
            lines.append(f"  - {warning}")

    return "\n".join(lines)
