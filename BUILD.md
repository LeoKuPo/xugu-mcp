# Build & Release Guide

This document describes the build and release process for `xugu-mcp` package.

## Prerequisites

- Python 3.11+
- `uv` package manager (recommended) or `pip`
- PyPI account (for publishing)
- API token from [PyPI Account Settings](https://pypi.org/manage/account/token/)

## Environment Setup

### 1. Install Dependencies

```bash
# Using uv (recommended)
uv sync

# Or using pip
pip install build hatchling twine
```

### 2. Configure PyPI Credentials

Create `~/.pypirc`:

```ini
[distutils]
index-servers =
    pypi
    testpypi

[pypi]
username = __token__
password = <your-pypi-api-token>

[testpypi]
username = __token__
password = <your-testpypi-api-token>
```

Or use environment variables:

```bash
export TWINE_USERNAME=__token__
export TWINE_PASSWORD=pypi-<your-api-token>
```

## Build Process

### Step 1: Clean Previous Builds

```bash
rm -rf dist/ build/ *.egg-info __pycache__
find . -type d -name "__pycache__" -exec rm -rf {} +
```

### Step 2: Build the Package

```bash
# Using uv
uv build

# Or using Python module
python -m build

# Or using pip
pip install build
python -m build
```

This creates:
- `dist/xugu_mcp-<version>.tar.gz` - Source distribution (sdist)
- `dist/xugu_mcp-<version>-py3-none-any.whl` - Wheel distribution

### Step 3: Verify the Build

```bash
# Check package contents
twine check dist/*

# Or inspect wheel file
unzip -l dist/*.whl

# Test install locally
pip install dist/*.whl --force-reinstall
```

### Step 4: Upload to TestPyPI (Optional)

```bash
# Upload to TestPyPI for testing
twine upload --repository testpypi dist/*

# Install from TestPyPI
pip install --index-url https://test.pypi.org/simple/ xugu-mcp
```

### Step 5: Upload to PyPI

```bash
# Upload to PyPI
twine upload dist/*
```

## Build Configuration

The package uses `hatchling` as the build backend (configured in `pyproject.toml`):

### Included Packages

- `src/xugu_mcp` - Main package
- `xgcondb` - Platform adapter

### Platform-Specific Binaries

- `xgcondb-mac/` - macOS binaries (.so)
- `xgcondb-linux-64/` - Linux x86_64 binaries (.so)
- `xgcondb-linux-arm64/` - Linux ARM64 binaries (.so)
- `xgcondb-win/` - Windows binaries (.dll, .pyd)

## Version Bumping

To release a new version:

1. Update version in `pyproject.toml`:

```toml
[project]
version = "0.2.0"  # Increment version
```

2. Update `CHANGELOG.md` with release notes

3. Commit changes:

```bash
git add pyproject.toml CHANGELOG.md
git commit -m "Release v0.2.0"
git tag v0.2.0
```

4. Build and publish:

```bash
rm -rf dist/
uv build
twine upload dist/*
```

5. Push tag to GitHub:

```bash
git push origin main --tags
```

## Quick Release Script

```bash
#!/bin/bash
# release.sh - Quick release script

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: ./release.sh <version>"
    exit 1
fi

# Update version
sed -i '' "s/version = \".*\"/version = \"$VERSION\"/" pyproject.toml

# Clean and build
rm -rf dist/ build/
uv build

# Check
twine check dist/*

# Upload
read -p "Upload to PyPI? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    twine upload dist/*
    git add pyproject.toml
    git commit -m "Release v$VERSION"
    git tag "v$VERSION"
    git push origin main --tags
fi
```

Usage:
```bash
chmod +x release.sh
./release.sh 0.2.0
```

## Troubleshooting

### Build Fails

```bash
# Ensure clean state
rm -rf dist/ build/ *.egg-info

# Verify dependencies
uv sync

# Rebuild
uv build
```

### Upload Fails - 403 Forbidden

- Verify API token is correct
- Check package name isn't already taken
- Ensure you have owner permissions

### Upload Fails - File Already Exists

- Version already exists on PyPI
- Bump version number in `pyproject.toml`

### Large Package Size

The package includes platform-specific binaries, making it larger than typical Python packages. This is expected for database drivers.

## Post-Release Checklist

- [ ] Verify package appears on PyPI: https://pypi.org/project/xugu-mcp/
- [ ] Test install from PyPI: `pip install xugu-mcp`
- [ ] Update GitHub Releases page
- [ ] Announce release (if applicable)
- [ ] Monitor for issues

## Links

- PyPI: https://pypi.org/project/xugu-mcp/
- GitHub: https://github.com/xugudb/xugu-mcp
- TestPyPI: https://test.pypi.org/project/xugu-mcp/
