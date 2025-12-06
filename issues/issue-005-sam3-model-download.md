# Issue 005: SAM3 Model Download from HuggingFace

## Problem Description

The SAM3 model checkpoint (`sam3.pt`) is large (~2.4GB) and needs to be downloaded from HuggingFace on first use. This can cause delays or failures if:
- Internet connection is slow or unstable
- HuggingFace is inaccessible
- Disk space is insufficient
- Authentication is required

## Model Information

- **Model ID**: `facebook/sam3`
- **Checkpoint file**: `sam3.pt`
- **Size**: ~2.4GB
- **Location**: HuggingFace cache directory (typically `~/.cache/huggingface/hub/`)

## Automatic Download

The model is automatically downloaded when:
1. Server starts and loads SAM3 model
2. First prediction request is made
3. Model checkpoint path is not found locally

The download happens in `app/models/sam3/model_builder.py`:
```python
def download_ckpt_from_hf():
    SAM3_MODEL_ID = "facebook/sam3"
    SAM3_CKPT_NAME = "sam3.pt"
    checkpoint_path = hf_hub_download(
        repo_id=SAM3_MODEL_ID,
        filename=SAM3_CKPT_NAME
    )
    return checkpoint_path
```

## Potential Issues

### Issue: Slow Download

**Symptoms**: Server takes a long time to start on first run

**Solution**: 
- Ensure stable internet connection
- Download will resume if interrupted
- Model is cached after first download

### Issue: HuggingFace Access Denied

**Symptoms**: `403 Forbidden` or authentication errors

**Solutions**:
1. Login to HuggingFace:
   ```bash
   huggingface-cli login
   ```

2. Set HuggingFace token:
   ```bash
   export HF_TOKEN="your_token_here"
   ```

3. Use mirror (if in restricted region):
   ```python
   # Set environment variable
   export HF_ENDPOINT=https://hf-mirror.com
   ```

### Issue: Insufficient Disk Space

**Symptoms**: Download fails with disk space error

**Solution**:
1. Check available space:
   ```bash
   df -h ~/.cache/huggingface/
   ```

2. Free up space or change cache location:
   ```bash
   export HF_HOME=/path/to/larger/disk/.cache/huggingface
   ```

### Issue: Manual Download

**Solution**: Download manually and place in expected location:

```python
from huggingface_hub import hf_hub_download
import os

# Download to specific location
checkpoint_path = hf_hub_download(
    repo_id="facebook/sam3",
    filename="sam3.pt",
    cache_dir="/path/to/cache"
)

print(f"Model saved to: {checkpoint_path}")
```

Then update config:
```yaml
params:
  model_path: "/path/to/cache/models--facebook--sam3/snapshots/.../sam3.pt"
```

## Verification

After first server start, check if model is downloaded:
```bash
ls -lh ~/.cache/huggingface/hub/models--facebook--sam3/
```

You should see the `sam3.pt` file (~2.4GB).

## Related Files

- `X-AnyLabeling-Server/app/models/sam3/model_builder.py`
- `X-AnyLabeling-Server/configs/auto_labeling/segment_anything_3.yaml`

## Status

✅ **RESOLVED** - Model download is automatic. First server start will download the model if not present.

