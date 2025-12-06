# Issue 006: SAM3 BPE Tokenizer File Missing

## Problem Description

During server startup, SAM3 model loading fails with:
```
ERROR: Failed to load model [segment_anything_3]: [Errno 2] No such file or directory: 'bpe_simple_vocab_16e6.txt.gz'
```

## Error Details

The SAM3 model requires a BPE (Byte Pair Encoding) tokenizer file for text processing. The config file specifies:
```yaml
params:
  bpe_path: "bpe_simple_vocab_16e6.txt.gz"
```

However, this file is not included in the repository and must be downloaded separately.

## Root Cause

1. The BPE file is not bundled with the X-AnyLabeling-Server repository
2. The file is not available on HuggingFace (404 error)
3. The default path in `model_builder.py` expects the file at `app/models/assets/bpe_simple_vocab_16e6.txt.gz`

## Solution

### Automatic Download (Implemented)

The BPE file can be downloaded from the OpenAI CLIP repository, which uses the same tokenizer:

```bash
cd X-AnyLabeling-Server/app/models/assets
python3 -c "
import requests
url = 'https://github.com/openai/CLIP/raw/main/clip/bpe_simple_vocab_16e6.txt.gz'
response = requests.get(url, timeout=30)
if response.status_code == 200:
    with open('bpe_simple_vocab_16e6.txt.gz', 'wb') as f:
        f.write(response.content)
    print('Downloaded BPE file successfully')
"
```

### Manual Download

Alternatively, download manually:

```bash
cd X-AnyLabeling-Server/app/models/assets
mkdir -p assets
curl -L -o bpe_simple_vocab_16e6.txt.gz \
  "https://github.com/openai/CLIP/raw/main/clip/bpe_simple_vocab_16e6.txt.gz"
```

### Updated Code

The `segment_anything_3.py` model loader now:
1. Checks if the BPE path exists
2. Tries to resolve relative paths
3. Falls back to model_builder default if not found
4. Logs a warning but continues (model_builder will use its default)

## Verification

After downloading the BPE file:

```bash
ls -lh X-AnyLabeling-Server/app/models/assets/bpe_simple_vocab_16e6.txt.gz
# Should show: -rw-rw-r-- 1 user user 1.3M ... bpe_simple_vocab_16e6.txt.gz

file X-AnyLabeling-Server/app/models/assets/bpe_simple_vocab_16e6.txt.gz
# Should show: gzip compressed data
```

Restart the server - the warning should disappear and SAM3 should load (if model checkpoint is also available).

## Related Files

- `X-AnyLabeling-Server/app/models/segment_anything_3.py`
- `X-AnyLabeling-Server/app/models/sam3/model_builder.py`
- `X-AnyLabeling-Server/configs/auto_labeling/segment_anything_3.yaml`
- `X-AnyLabeling-Server/app/models/assets/bpe_simple_vocab_16e6.txt.gz` (after download)

## Status

✅ **RESOLVED** - BPE file downloaded from OpenAI CLIP repository. The file is now available at the expected location.

