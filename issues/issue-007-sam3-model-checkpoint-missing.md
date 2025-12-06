# Issue 007: SAM3 Model Checkpoint Missing on First Run

## Problem Description

During server startup, SAM3 model loading fails with:
```
ERROR: Failed to load model [segment_anything_3]: [Errno 2] No such file or directory: 'sam3.pt'
```

## Error Details

The SAM3 model checkpoint (`sam3.pt`, ~2.4GB) is not included in the repository and must be downloaded from HuggingFace on first use.

## Root Cause

The SAM3 model checkpoint is large (~2.4GB) and is automatically downloaded from HuggingFace when needed. On first server start, the checkpoint hasn't been downloaded yet.

## Expected Behavior

This is **expected behavior** - the model checkpoint will be automatically downloaded from HuggingFace when:
1. The server starts and attempts to load SAM3
2. The first prediction request is made with SAM3

The download happens in `app/models/sam3/model_builder.py`:
```python
def download_ckpt_from_hf():
    SAM3_MODEL_ID = "facebook/sam3"
    SAM3_CKPT_NAME = "sam3.pt"
    checkpoint_path = hf_hub_download(
        repo_id=SAM3_MODEL_ID, filename=SAM3_CKPT_NAME
    )
    return checkpoint_path
```

## Solution

### Automatic Download (Default)

The model will be downloaded automatically on first use. No action needed.

### Manual Download (Optional)

To download the model checkpoint manually before first use:

```python
from huggingface_hub import hf_hub_download

checkpoint_path = hf_hub_download(
    repo_id="facebook/sam3",
    filename="sam3.pt"
)
print(f"Model saved to: {checkpoint_path}")
```

Or using command line:
```bash
huggingface-cli download facebook/sam3 sam3.pt --local-dir ./models
```

### Pre-download During Installation

The installation script could be enhanced to pre-download the model, but this is optional since:
- The model is large (~2.4GB)
- Download happens automatically when needed
- Not all users may need SAM3

## Impact

- **Server Status**: Server starts successfully with 5/6 models loaded
- **SAM3 Availability**: SAM3 will be available after first download completes
- **Other Models**: All other models (YOLO11n variants) work normally

## Verification

After the model is downloaded (on first SAM3 prediction or manual download):

1. Check if model is cached:
   ```bash
   ls -lh ~/.cache/huggingface/hub/models--facebook--sam3/
   ```

2. Restart server and check logs:
   ```bash
   ./run.sh
   # Should see: "SAM3 model loaded successfully"
   ```

3. Verify in API:
   ```bash
   curl http://localhost:8014/v1/models | grep segment_anything_3
   ```

## Related Files

- `X-AnyLabeling-Server/app/models/sam3/model_builder.py`
- `X-AnyLabeling-Server/configs/auto_labeling/segment_anything_3.yaml`
- HuggingFace cache: `~/.cache/huggingface/hub/models--facebook--sam3/`

## Status

✅ **EXPECTED BEHAVIOR** - Model checkpoint will be downloaded automatically on first use. Server continues to run with other models while SAM3 downloads in the background.

