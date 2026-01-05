# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an MCP (Model Context Protocol) server for XuguDB (虚谷数据库), a Chinese database system. The project provides Python database connectivity tools following the Python Database API Specification v2.0 protocol.

## Development Environment

- **Python Version**: 3.12 (see `.python-version`)
- **Package Manager**: `uv` (fast Python package manager)
- **Project Type**: MCP server using the `mcp[cli]` package

## Common Commands

```bash
# Install dependencies
uv sync

# Run the project
uv run python main.py

# Run the MCP server
mcp dev .
```

## Project Structure

```
xugu-mcp/
├── main.py          # Entry point
├── pyproject.toml   # Project configuration and dependencies
├── xgcondb/         # XuguDB Python driver package (platform adapter)
│   └── __init__.py  # Platform detection and dynamic module loading
├── xgcondb-win/     # Windows (x86_64) driver
├── xgcondb-mac/     # macOS (darwin) driver
├── xgcondb-linux-64/    # Linux x86_64 driver
├── xgcondb-linux-arm64/ # Linux ARM64 driver
└── .python-version  # Python version specification
```

## XuguDB Driver Architecture

The `xgcondb` package provides **cross-platform support** with automatic platform detection:

### Platform-Specific Drivers

| Directory | Platform | Architecture | Files |
|-----------|----------|--------------|-------|
| `xgcondb-win/` | Windows | x86_64 | `.pyd` DLLs |
| `xgcondb-mac/` | macOS (Darwin) | Universal | `.so` binaries |
| `xgcondb-linux-64/` | Linux | x86_64 | `.so` binaries |
| `xgcondb-linux-arm64/` | Linux | ARM64 | `.so` binaries |

### Platform Adapter

The `xgcondb/__init__.py` automatically:
1. Detects the operating system and architecture
2. Loads the appropriate platform-specific driver
3. Exports a unified API (`connect()`, `Connection`, etc.)

**Supported Platforms**:
- Windows (x86_64)
- macOS (Darwin, universal)
- Linux (x86_64 and ARM64)

**Python Version Support**: Python 3.4 - 3.12+

### Connection Method

Use `xgcondb.connect()` with parameters:
- `host`: Database IP (comma-separated for multiple IPs)
- `port`: Database port (default: 5138)
- `database`: Database name
- `user`: Username (default: SYSDBA)
- `password`: Password
- `charset`: Client encoding (default: utf8)
- `usessl`: SSL connection ("true"/"on"/"yes" for encrypted)

### Thread Safety

- **Connection objects**: Thread-safe (can be shared across threads)
- **Cursor objects**: NOT thread-safe (use one cursor per thread)

### Connection Example

```python
import xgcondb

conn = xgcondb.connect(
    host="127.0.0.1",
    port="5138",
    database="SYSTEM",
    user="SYSDBA",
    password="SYSDBA",
    charset='UTF8'
)
cur = conn.cursor()
```

## Key Connection Parameters

- **host**: Database IP (comma-separated for multiple IPs)
- **port**: Database port (default: 5138)
- **database**: Database name
- **user**: Username (default: SYSDBA)
- **password**: Password
- **charset**: Client encoding (default: utf8)
- **usessl**: SSL connection ("true"/"on"/"yes" for encrypted)

## Database Documentation

Official Python driver documentation: https://docs.xugudb.com/content/development/python

Key features from documentation:
- Supports parameterized queries with `?` placeholders or `:name` for dict parameters
- Batch operations via `executemany()` and `executebatch()`
- Stored procedure execution via `callproc()`
- LOB (BLOB/CLOB) support for large objects
- Transaction control: `begin()`, `commit()`, `rollback()`, `autocommit()`
