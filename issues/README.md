# Installation Issues and Solutions

This directory contains documentation of issues encountered during the installation and setup of X-AnyLabeling-Server with SAM3 support, along with their solutions.

## Issue Index

1. **[Issue 001: SAM3 Model Import Test Failure](./issue-001-sam3-import-test-failure.md)**
   - Problem with SAM3 import path during installation test
   - Status: ✅ Resolved

2. **[Issue 002: Virtual Environment Removal on Re-installation](./issue-002-virtual-environment-removal.md)**
   - Script was removing existing venv on re-run
   - Status: ✅ Resolved

3. **[Issue 003: PyTorch CUDA Installation and Verification](./issue-003-pytorch-cuda-verification.md)**
   - PyTorch CUDA setup and verification process
   - Status: ✅ Resolved

4. **[Issue 004: SAM3 Device Configuration for Multi-GPU Systems](./issue-004-sam3-device-configuration.md)**
   - Configuring SAM3 to use correct GPU device
   - Status: ✅ Resolved

5. **[Issue 005: SAM3 Model Download from HuggingFace](./issue-005-sam3-model-download.md)**
   - Automatic model download and potential issues
   - Status: ✅ Resolved

6. **[Issue 006: SAM3 BPE Tokenizer File Missing](./issue-006-sam3-bpe-file-missing.md)**
   - BPE tokenizer file not found during SAM3 loading
   - Status: ✅ Resolved

7. **[Issue 007: SAM3 Model Checkpoint Missing on First Run](./issue-007-sam3-model-checkpoint-missing.md)**
   - SAM3 checkpoint file missing (expected, downloads automatically)
   - Status: ✅ Expected Behavior

## Format

Each issue document follows this structure:
- **Problem Description**: What the issue is
- **Error Details**: Specific error messages or symptoms
- **Root Cause**: Why the issue occurred
- **Solution**: How it was fixed
- **Verification**: How to confirm the fix works
- **Related Files**: Files that were modified or are relevant
- **Status**: Current resolution status

## Contributing

When documenting new issues:
1. Create a new file: `issue-{number}-{short-description}.md`
2. Follow the standard format above
3. Update this README with the new issue
4. Use sequential numbering

## Quick Reference

### Common Issues

- **Import errors**: Check Python path and module structure
- **CUDA issues**: Verify PyTorch CUDA version matches system CUDA
- **Model download**: Check internet connection and HuggingFace access
- **GPU configuration**: Verify device setting in config file

### Useful Commands

```bash
# Check PyTorch CUDA
python3 -c "import torch; print(torch.cuda.is_available())"

# Check GPU status
nvidia-smi

# Check CUDA version
nvcc --version

# Verify SAM3 import
cd X-AnyLabeling-Server
python3 -c "from app.models.segment_anything_3 import SegmentAnything3"
```

