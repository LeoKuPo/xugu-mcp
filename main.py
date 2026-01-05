"""
Development entry point for XuguDB MCP Server.

This is a simple script for testing the server during development.
For production, use the installed 'xugu-mcp' command.
"""
import sys
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from xugu_mcp.main import cli_main

if __name__ == "__main__":
    cli_main()
