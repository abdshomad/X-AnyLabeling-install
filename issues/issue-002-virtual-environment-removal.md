# Issue 002: Virtual Environment Removal on Re-installation

## Problem Description

When re-running the installation script, it would remove and recreate the existing virtual environment, causing:
- Loss of installed packages
- Unnecessary re-downloading of dependencies
- Longer installation time
- Potential loss of custom configurations

## Error Details

The original script behavior:
```bash
if [ -d "$VENV_DIR" ]; then
    log_warning "Virtual environment already exists. Removing old one..."
    rm -rf "$VENV_DIR"
fi
python3 -m venv "$VENV_DIR"
```

This would delete the entire venv directory and recreate it from scratch every time.

## Root Cause

The script was designed to ensure a clean installation by removing any existing virtual environment. However, this is not ideal for:
- Re-running installations to update dependencies
- Preserving custom package installations
- Faster subsequent installations

## Solution

Modified Step 5 in `install.sh` to reuse existing virtual environment:

```bash
# Step 5: Create virtual environment
log "Step 5: Checking virtual environment..."
if [ -d "$VENV_DIR" ]; then
    log_success "Virtual environment already exists. Using existing: $VENV_DIR"
else
    log "Creating new virtual environment..."
    python3 -m venv "$VENV_DIR"
    log_success "Virtual environment created: $VENV_DIR"
fi
```

## Benefits

1. **Faster re-installations**: Existing packages are preserved
2. **No data loss**: Custom packages and configurations remain
3. **Idempotent**: Can run multiple times safely
4. **Better UX**: Clear messaging about using existing environment

## Verification

After the fix, re-running the installation:
```
Step 5: Checking virtual environment...
✓ Virtual environment already exists. Using existing: /home/aiserver/LABS/X-ANYLABELING/X-AnyLabeling-Install/venv-server
```

The installation continues normally, upgrading packages as needed without removing the entire environment.

## Related Files

- `X-AnyLabeling-Install/install.sh` (Step 5)

## Status

✅ **RESOLVED** - The script now reuses existing virtual environments instead of removing them.

