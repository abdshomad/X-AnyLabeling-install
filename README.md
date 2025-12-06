# X-AnyLabeling-Server Installation Guide

## Table of Contents

- [System Requirements](#system-requirements)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Management Scripts](#management-scripts)
  - [Script Overview](#script-overview)
  - [Start vs Run Scripts](#start-vs-run-scripts)
  - [Server Scripts](#server-scripts)
  - [Client Scripts](#client-scripts)
  - [Combined Scripts](#combined-scripts)
- [SAM3 Configuration](#sam3-configuration)
- [Verification](#verification)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Integration with X-AnyLabeling Client](#integration-with-x-anylabeling-client)

## System Requirements

### Detected Hardware Configuration

This installation guide is configured for the following system:

- **GPUs**: 2x NVIDIA L40 (46GB each)
- **CUDA Version**: 12.6.85
- **NVIDIA Driver**: 580.95.05
- **Python**: 3.12.11

### Minimum Requirements for SAM3

For stable SAM3 operation, ensure your system meets these requirements:

- **Python**: 3.12 or higher
- **PyTorch**: 2.7 or higher
- **CUDA**: 12.6 or higher
- **GPU**: CUDA-compatible GPU with sufficient VRAM (recommended: 16GB+)
- **RAM**: 16GB minimum (32GB recommended)
- **Storage**: 10GB free space for models and dependencies

## Prerequisites

### 1. Python Environment

Verify Python version:

```bash
python3 --version
```

Must be Python 3.12 or higher for SAM3 support.

### 2. CUDA and GPU Verification

Check CUDA version:

```bash
nvcc --version
```

Verify GPU availability:

```bash
nvidia-smi
```

You should see your GPUs listed. For this system, you should see 2x NVIDIA L40 GPUs.

### 3. Package Manager

We recommend using `uv` for faster installation:

```bash
pip install --upgrade uv
```

Alternatively, you can use standard `pip`.

## Installation

### Automated Installation

The easiest way to install X-AnyLabeling-Server with SAM3 support is using the provided installation script:

```bash
cd X-AnyLabeling-Install
chmod +x install-server.sh
./install-server.sh
```

To install both server and client:

```bash
./install-all.sh
```

The script will:
1. Verify Python version (3.12+)
2. Detect and verify GPUs
3. Check CUDA version (12.6+)
4. Create a virtual environment
5. Install PyTorch with CUDA support
6. Install X-AnyLabeling-Server with all dependencies
7. Download SAM3 model checkpoint if needed
8. Configure SAM3 model settings

### Manual Installation

#### Step 1: Clone the Repository

```bash
cd /home/aiserver/LABS/X-ANYLABELING
git clone https://github.com/CVHub520/X-AnyLabeling-Server.git
cd X-AnyLabeling-Server
```

#### Step 2: Create Virtual Environment

```bash
python3 -m venv venv-server
source venv-server/bin/activate
```

#### Step 3: Install PyTorch with CUDA Support

For CUDA 12.6, install PyTorch 2.7+:

```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
```

Verify PyTorch CUDA installation:

```python
python3 -c "import torch; print(f'PyTorch: {torch.__version__}'); print(f'CUDA Available: {torch.cuda.is_available()}'); print(f'CUDA Version: {torch.version.cuda}'); print(f'GPU Count: {torch.cuda.device_count()}')"
```

#### Step 4: Install X-AnyLabeling-Server

Install with all dependencies (recommended for SAM3):

```bash
pip install --upgrade uv
uv pip install -e .[all]
```

Or using pip:

```bash
pip install -e .[all]
```

This installs:
- Core framework
- Ultralytics dependencies
- Transformers dependencies
- SAM3 dependencies (torch>=2.7.0, timm>=1.0.17, etc.)

#### Step 5: Verify Installation

```bash
python3 -c "from app import __version__; print(f'X-AnyLabeling-Server v{__version__}')"
```

## SAM3 Configuration

### Model Download

The SAM3 model checkpoint will be automatically downloaded from HuggingFace on first use. The model file (`sam3.pt`) will be saved to the HuggingFace cache directory.

To manually download or verify:

```python
from app.models.sam3.model_builder import download_ckpt_from_hf
checkpoint_path = download_ckpt_from_hf()
print(f"Model saved to: {checkpoint_path}")
```

### Configuration File

Edit `configs/auto_labeling/segment_anything_3.yaml`:

```yaml
model_id: segment_anything_3
display_name: "Segment Anything 3"
batch_processing_mode: "text_prompt"

params:
  bpe_path: "bpe_simple_vocab_16e6.txt.gz"  # BPE tokenizer (included)
  model_path: "sam3.pt"  # Will be downloaded from HuggingFace
  device: "cuda:0"  # Use cuda:0 for first GPU, cuda:1 for second GPU
  conf_threshold: 0.50
  show_boxes: true
  show_masks: true
  epsilon_factor: 0.001
```

### Multi-GPU Configuration

With 2x NVIDIA L40 GPUs, you can:

1. **Use first GPU (default)**: Set `device: "cuda:0"` in config
2. **Use second GPU**: Set `device: "cuda:1"` in config
3. **Load balancing**: Run multiple server instances on different GPUs

To use the second GPU, modify the config:

```yaml
params:
  device: "cuda:1"  # Use second GPU
```

## Management Scripts

This directory contains a comprehensive set of management scripts for both X-AnyLabeling Server and Client. All scripts follow a consistent naming pattern:

- **Server scripts**: `*-server.sh` (e.g., `start-server.sh`, `run-server.sh`)
- **Client scripts**: `*-client.sh` (e.g., `start-client.sh`, `run-client.sh`)
- **Combined scripts**: `*-all.sh` (e.g., `start-all.sh`, `monitor-all.sh`)

### Script Overview

| Script Type | Server | Client | Combined |
|------------|--------|--------|----------|
| **Install** | `install-server.sh` | `install-client.sh` | `install-all.sh` |
| **Start** | `start-server.sh` | `start-client.sh` | `start-all.sh` |
| **Run** | `run-server.sh` | `run-client.sh` | - |
| **Stop** | `stop-server.sh` | `stop-client.sh` | `stop-all.sh` |
| **Restart** | `restart-server.sh` | `restart-client.sh` | `restart-all.sh` |
| **Monitor** | `monitor-server.sh` | `monitor-client.sh` | `monitor-all.sh` |

### Start vs Run Scripts

The key difference between `start*.sh` and `run*.sh` scripts:

#### `start*.sh` (Production Mode)
- **Execution**: Runs in **background** (daemon mode)
- **Terminal**: Returns control immediately
- **Logging**: Output goes to log files (`logs/server.log`, `logs/client.log`)
- **PID Tracking**: Creates PID files for process management
- **Auto-reload**: No (server runs without `--reload`)
- **Use Case**: Production deployment, long-running services
- **Example**:
  ```bash
  ./start-server.sh    # Starts in background, returns to prompt
  ./monitor-server.sh # Check status
  tail -f logs/server.log  # View logs
  ```

#### `run*.sh` (Development Mode)
- **Execution**: Runs in **foreground** (blocks terminal)
- **Terminal**: Blocks until stopped (Ctrl+C)
- **Logging**: Output goes directly to terminal
- **PID Tracking**: No PID file created
- **Auto-reload**: Yes (server uses `--reload` flag)
- **Use Case**: Development, testing, debugging
- **Example**:
  ```bash
  ./run-server.sh     # Blocks terminal, shows live output
  # Press Ctrl+C to stop
  # See errors immediately
  # Code changes auto-reload (server only)
  ```

**Summary**: Use `start*.sh` for production (background, logged, managed) and `run*.sh` for development (foreground, interactive, auto-reload).

### Server Scripts

#### Installation
```bash
./install-server.sh
```
Installs X-AnyLabeling-Server with GPU support, creates `venv-server` virtual environment.

#### Starting the Server

**Production Mode (Background)**:
```bash
./start-server.sh
```
- Starts server in background
- Logs to `logs/server.log`
- Creates `server.pid` for tracking
- Returns control to terminal

**Development Mode (Foreground)**:
```bash
./run-server.sh
```
- Runs server in foreground
- Shows output in terminal
- Auto-reloads on code changes
- Press Ctrl+C to stop

#### Stopping the Server
```bash
./stop-server.sh
```
Gracefully stops the running server.

#### Restarting the Server
```bash
./restart-server.sh
```
Stops and then starts the server.

#### Monitoring the Server
```bash
./monitor-server.sh
```
Displays:
- Server status (running/stopped)
- Process information (PID, CPU, memory)
- GPU usage statistics
- Recent logs
- Health check status

### Client Scripts

#### Installation
```bash
./install-client.sh
```
Installs X-AnyLabeling client with GPU support, creates `venv-client` virtual environment, and configures connection to server.

#### Starting the Client

**Production Mode (Background)**:
```bash
./start-client.sh
```
- Starts client GUI in background
- Logs to `logs/client.log`
- Creates `client.pid` for tracking

**Development Mode (Foreground)**:
```bash
./run-client.sh
```
- Runs client GUI in foreground
- Shows output in terminal
- Press Ctrl+C to stop

#### Stopping the Client
```bash
./stop-client.sh
```
Gracefully stops the running client.

#### Restarting the Client
```bash
./restart-client.sh
```
Stops and then starts the client.

#### Monitoring the Client
```bash
./monitor-client.sh
```
Displays:
- Client status (running/stopped)
- Process information
- GPU usage statistics
- Recent logs

### Combined Scripts

#### Install Both
```bash
./install-all.sh
```
Installs both server and client in sequence.

#### Start Both
```bash
./start-all.sh
```
Starts both server and client together (server first, then client).

#### Stop Both
```bash
./stop-all.sh
```
Stops both server and client (client first, then server).

#### Restart Both
```bash
./restart-all.sh
```
Restarts both server and client. Handles failures gracefully (continues even if one service fails).

#### Monitor Both
```bash
./monitor-all.sh
```
Displays status of both server and client side-by-side, including:
- Server and client status
- GPU usage
- Server health check
- Recent logs from both services

## Verification

### 1. Check Server Health

Start the server:

```bash
cd X-AnyLabeling-Install
./start-server.sh    # Production mode (background)
# or
./run-server.sh      # Development mode (foreground)
```

The server uses port 8014 by default (configured in `.env` file).

In another terminal, check health:

```bash
curl http://localhost:8014/v1/health
```

### 2. Verify Models are Loaded

```bash
curl http://localhost:8014/v1/models
```

You should see `segment_anything_3` in the list of available models.

### 3. Test SAM3 Model Loading

The server will attempt to load SAM3 on startup. Check the logs for:

```
Loading SAM3 model from sam3.pt
SAM3 model loaded successfully
```

If you see errors, check the [Troubleshooting](#troubleshooting) section.

### 4. GPU Memory Usage

Monitor GPU usage:

```bash
watch -n 1 nvidia-smi
```

When SAM3 is loaded, you should see GPU memory usage increase.

## Usage

### Quick Start

1. **Install everything**:
   ```bash
   cd X-AnyLabeling-Install
   ./install-all.sh
   ```

2. **Start both services**:
   ```bash
   ./start-all.sh
   ```

3. **Monitor both services**:
   ```bash
   ./monitor-all.sh
   ```

### Starting the Server

#### Development Mode (Foreground)

```bash
cd X-AnyLabeling-Install
./run-server.sh
```

Or manually (using port from .env, default 8014):

```bash
cd X-AnyLabeling-Server
source ../X-AnyLabeling-Install/venv-server/bin/activate
# Load port from .env
source ../X-AnyLabeling-Install/.env
uvicorn app.main:app --host ${HOST:-0.0.0.0} --port ${PORT:-8014} --reload
```

#### Production Mode (Background)

```bash
cd X-AnyLabeling-Install
./start-server.sh
```

This starts the server in the background with logging to `logs/server.log`.

### Starting the Client

#### Development Mode (Foreground)

```bash
cd X-AnyLabeling-Install
./run-client.sh
```

#### Production Mode (Background)

```bash
cd X-AnyLabeling-Install
./start-client.sh
```

This starts the client in the background with logging to `logs/client.log`.

### Stopping Services

**Stop server**:
```bash
./stop-server.sh
```

**Stop client**:
```bash
./stop-client.sh
```

**Stop both**:
```bash
./stop-all.sh
```

### Monitoring

**Monitor server**:
```bash
./monitor-server.sh
```

**Monitor client**:
```bash
./monitor-client.sh
```

**Monitor both**:
```bash
./monitor-all.sh
```

Monitor scripts show:
- Service status (running/stopped)
- Process information (PID, CPU, memory)
- Recent logs
- GPU usage statistics
- Server health check (server only)

### Using SAM3 in X-AnyLabeling Client

1. **Install and start both services**:
   ```bash
   cd X-AnyLabeling-Install
   ./install-all.sh    # Install both (if not already installed)
   ./start-all.sh      # Start both server and client
   ```

2. **Client configuration** - The `install-client.sh` script automatically configures the client to connect to the server. The configuration is in `X-AnyLabeling/anylabeling/configs/auto_labeling/remote_server.yaml`:
   ```yaml
   server_url: http://localhost:8014
   api_key: ""  # Leave empty if authentication is disabled
   ```
   
   Note: The default port is 8014 (configured in `X-AnyLabeling-Install/.env`). Change it if you modified the port in the `.env` file.

3. **Launch X-AnyLabeling client** (if not using start scripts):
   ```bash
   cd X-AnyLabeling-Install
   ./run-client.sh     # Development mode (foreground)
   # or
   ./start-client.sh    # Production mode (background)
   ```
   
   Or manually:
   ```bash
   cd X-AnyLabeling
   source ../X-AnyLabeling-Install/venv-client/bin/activate
   python3 -m anylabeling.app
   ```

4. **Enable AI auto-labeling**: Press `Ctrl+A` or click the `AI` button

5. **Select model**: 
   - Open the model dropdown
   - Navigate to **CVHub** provider section
   - Select **Remote-Server**
   - Choose **Segment Anything 3**

6. **Use SAM3**:
   - **Text Prompting**: Enter object names (e.g., `person`, `car`, `bicycle`) separated by commas or periods
   - **Visual Prompting**: Use `+Rect` or `-Rect` to draw bounding boxes, then click **Run Rect**

## Troubleshooting

### Issue: Python Version Too Old

**Error**: `Python 3.12+ required for SAM3`

**Solution**: Upgrade Python to 3.12 or higher. Use conda or pyenv to manage Python versions.

### Issue: CUDA Version Mismatch

**Error**: `CUDA 12.6+ required for SAM3`

**Solution**: 
- Update CUDA toolkit to 12.6 or higher
- Reinstall PyTorch with matching CUDA version:
  ```bash
  pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu126
  ```

### Issue: PyTorch Not Detecting GPU

**Error**: `CUDA not available` or `torch.cuda.is_available() returns False`

**Solution**:
1. Verify NVIDIA driver: `nvidia-smi`
2. Check PyTorch CUDA installation:
   ```python
   import torch
   print(torch.cuda.is_available())
   print(torch.version.cuda)
   ```
3. Reinstall PyTorch with CUDA support if needed

### Issue: Out of Memory (OOM)

**Error**: `CUDA out of memory`

**Solution**:
- SAM3 requires significant VRAM. With 46GB per GPU, this should not be an issue
- If using multiple models, consider using different GPUs:
  - Model 1: `cuda:0`
  - Model 2: `cuda:1`
- Reduce batch size if processing multiple images

### Issue: SAM3 Model Download Fails

**Error**: `Failed to download model from HuggingFace`

**Solution**:
1. Check internet connection
2. Verify HuggingFace access: `huggingface-cli login` (if needed)
3. Manually download and place model file:
   ```python
   from huggingface_hub import hf_hub_download
   model_path = hf_hub_download(repo_id="facebook/sam3", filename="sam3.pt")
   ```

### Issue: Server Won't Start

**Error**: `Address already in use` or port conflicts

**Solution**:
1. Check if server is already running: `./monitor-server.sh`
2. Stop existing server: `./stop-server.sh`
3. Use a different port:
   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8001
   ```

### Issue: Model Loading Fails

**Error**: `Error during model loading` in server logs

**Solution**:
1. Check model path in `configs/auto_labeling/segment_anything_3.yaml`
2. Verify model file exists
3. Check GPU availability: `nvidia-smi`
4. Review full error in server logs: `logs/server.log`

### Issue: Client Cannot Connect to Server

**Error**: Connection refused or timeout

**Solution**:
1. Verify server is running: `./monitor-server.sh`
2. Check server URL in `remote_server.yaml`
3. Test connection: `curl http://localhost:8014/v1/health`
4. Check firewall settings if connecting remotely

## Integration with X-AnyLabeling Client

The X-AnyLabeling client can connect to the server for remote model inference. The integration allows:

- **Remote Model Access**: Use server-hosted models without installing them locally
- **GPU Acceleration**: Leverage server GPUs for faster inference
- **Multi-User Support**: Multiple clients can connect to the same server
- **Resource Management**: Centralized model management and updates

### Configuration

1. **Server Configuration** (`X-AnyLabeling-Server/configs/server.yaml`):
   ```yaml
   server:
     host: "0.0.0.0"
     port: 8014  # Default port (can be changed in X-AnyLabeling-Install/.env)
   security:
     api_key_enabled: false  # Set to true for production
     api_key: ""  # Set API key if enabled
   ```

2. **Client Configuration** (`X-AnyLabeling/anylabeling/configs/auto_labeling/remote_server.yaml`):
   ```yaml
   server_url: http://localhost:8014
   api_key: ""  # Match server API key if enabled
   timeout: 30
   ```
   
   Note: The port (8014) should match the `PORT` value in `X-AnyLabeling-Install/.env`.

### Auto-Start Integration (Optional)

For seamless integration, the client can automatically start the server if it's not running. This feature is available through the server manager module (see implementation details).

## Additional Resources

- [X-AnyLabeling-Server Documentation](https://github.com/CVHub520/X-AnyLabeling-Server)
- [X-AnyLabeling Client Documentation](https://github.com/CVHub520/X-AnyLabeling)
- [SAM3 Paper](https://ai.meta.com/research/publications/sam-3-segment-anything-with-concepts/)
- [PyTorch Installation Guide](https://pytorch.org/get-started/locally/)
- [CUDA Installation Guide](https://developer.nvidia.com/cuda-downloads)

## Support

For issues specific to this installation, check the `issues/` directory for documented problems and solutions.

For general support:
- [X-AnyLabeling-Server Issues](https://github.com/CVHub520/X-AnyLabeling-Server/issues)
- [X-AnyLabeling Issues](https://github.com/CVHub520/X-AnyLabeling/issues)

