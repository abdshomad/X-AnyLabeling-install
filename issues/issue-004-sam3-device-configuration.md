# Issue 004: SAM3 Device Configuration for Multi-GPU Systems

## Problem Description

With a system having 2x NVIDIA L40 GPUs, SAM3 needs to be configured to use the correct GPU device. The default configuration might not be optimal for multi-GPU setups.

## System Configuration

- **GPUs**: 2x NVIDIA L40 (46GB each)
- **Default device**: cuda:0 (first GPU)
- **Alternative**: cuda:1 (second GPU) for load balancing

## Configuration Location

SAM3 device is configured in:
```
X-AnyLabeling-Server/configs/auto_labeling/segment_anything_3.yaml
```

Default configuration:
```yaml
params:
  device: "cuda:0"  # Uses first GPU
```

## Solution Implementation

The installation script (Step 12) automatically configures the device:

```bash
# Set device to cuda:0 if GPUs are available
if [ "$GPU_COUNT" -gt 0 ]; then
    # Check if device is already configured
    if ! grep -q "device:" "$SAM3_CONFIG" || grep -q "device: \"cpu\"" "$SAM3_CONFIG"; then
        log "Setting SAM3 device to cuda:0..."
        sed -i 's/device:.*/device: "cuda:0"/' "$SAM3_CONFIG"
    fi
fi
```

## Multi-GPU Usage Options

### Option 1: Use First GPU (Default)
```yaml
params:
  device: "cuda:0"
```

### Option 2: Use Second GPU
```yaml
params:
  device: "cuda:1"
```

### Option 3: Run Multiple Server Instances
Run separate server instances on different GPUs:
- Instance 1: Port 8000, GPU 0
- Instance 2: Port 8001, GPU 1

## Manual Configuration

To change the GPU device manually:

1. Edit the config file:
   ```bash
   nano X-AnyLabeling-Server/configs/auto_labeling/segment_anything_3.yaml
   ```

2. Change the device parameter:
   ```yaml
   params:
     device: "cuda:1"  # Use second GPU
   ```

3. Restart the server for changes to take effect.

## Verification

Check GPU usage after starting the server:
```bash
nvidia-smi
```

You should see GPU memory usage increase when SAM3 model is loaded.

## Related Files

- `X-AnyLabeling-Install/install.sh` (Step 12)
- `X-AnyLabeling-Server/configs/auto_labeling/segment_anything_3.yaml`

## Status

✅ **RESOLVED** - SAM3 is configured to use cuda:0 by default. Can be changed to cuda:1 if needed.

