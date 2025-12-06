# Issue 003: PyTorch CUDA Installation and Verification

## Problem Description

During installation, PyTorch with CUDA support needs to be installed correctly and verified to ensure SAM3 can use GPU acceleration.

## Installation Requirements

For SAM3 to work properly, we need:
- PyTorch 2.7+ with CUDA 12.6+ support
- CUDA toolkit 12.6+
- Compatible NVIDIA GPU drivers

## Solution Implementation

The installation script handles this in Step 8:

1. **Detects GPU availability**:
   ```bash
   if [ "$GPU_COUNT" -gt 0 ]; then
       # Install PyTorch with CUDA
   fi
   ```

2. **Installs PyTorch with CUDA 12.6**:
   ```bash
   pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
   ```

3. **Verifies installation**:
   ```python
   python3 -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'CUDA Version: {torch.version.cuda}'); print(f'GPU Count: {torch.cuda.device_count()}')"
   ```

## Verification Results

On this system:
- PyTorch: 2.9.1+cu126
- CUDA Available: True
- CUDA Version: 12.6
- GPU Count: 2
- GPU 0: NVIDIA L40
- GPU 1: NVIDIA L40

## Potential Issues

### Issue: PyTorch CUDA not available

**Symptoms**: `torch.cuda.is_available()` returns `False`

**Possible causes**:
1. CUDA toolkit not installed
2. NVIDIA drivers not installed or outdated
3. PyTorch installed without CUDA support
4. CUDA version mismatch

**Solutions**:
1. Verify CUDA installation: `nvcc --version`
2. Check NVIDIA drivers: `nvidia-smi`
3. Reinstall PyTorch with correct CUDA version
4. Ensure CUDA toolkit version matches PyTorch CUDA version

### Issue: CUDA version mismatch

**Symptoms**: PyTorch installed but CUDA not detected

**Solution**: Install PyTorch with matching CUDA version:
```bash
# For CUDA 12.6
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
```

## Related Files

- `X-AnyLabeling-Install/install.sh` (Step 8)
- `X-AnyLabeling-Server/configs/auto_labeling/segment_anything_3.yaml` (device configuration)

## Status

✅ **RESOLVED** - PyTorch with CUDA 12.6 is correctly installed and verified on this system.

