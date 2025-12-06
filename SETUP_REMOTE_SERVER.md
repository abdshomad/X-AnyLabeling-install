# How to Setup Remote Server in X-AnyLabeling

This guide explains how to set up and use the Remote-Server feature in X-AnyLabeling to connect to X-AnyLabeling-Server.

## Quick Setup (Recommended)

### Step 1: Start the Server

The easiest way is to use the management scripts:

```bash
cd X-AnyLabeling-Install

# Start the server (production mode - background)
./start-server.sh

# Or start both server and client together
./start-all.sh
```

Verify the server is running:

```bash
# Check server status
./monitor-server.sh

# Or test the connection
curl http://localhost:8014/v1/health
```

You should see a response like:
```json
{"status":"healthy","models_loaded":6}
```

### Step 2: Start the Client

```bash
cd X-AnyLabeling-Install

# Start client (production mode - background)
./start-client.sh

# Or development mode (foreground)
./run-client.sh
```

### Step 3: Use Remote-Server in Client

1. **Open X-AnyLabeling client** (if not already open)
2. **Press `Ctrl+A`** or click the **AI** button to enable auto-labeling
3. **Select Remote-Server**:
   - Open the model dropdown
   - Navigate to **CVHub** provider section
   - Select **Remote-Server**
   - Choose your desired model (e.g., **Segment Anything 3**)

The client should now connect to the server successfully!

## Configuration

### Server URL Configuration

The client is configured to connect to `http://localhost:8014` by default. This is set in:

**File**: `X-AnyLabeling/anylabeling/configs/auto_labeling/remote_server.yaml`

```yaml
type: remote_server
name: remote_server-r20251104
provider: CVHub
display_name: Remote-Server
server_url: http://localhost:8014
api_key: ""
timeout: 30
auto_start_server: false
```

**To change the server URL**:
1. Edit the `remote_server.yaml` file
2. Update the `server_url` field
3. Restart the client

**To change the server port**:
1. Edit `X-AnyLabeling-Install/.env` file (create if it doesn't exist):
   ```bash
   PORT=8014
   XANYLABELING_PORT=8014
   ```
2. Restart the server

### Enable Auto-Start (Optional)

The client can automatically start the server if it's not running. To enable this:

1. **Edit** `X-AnyLabeling/anylabeling/configs/auto_labeling/remote_server.yaml`
2. **Change** `auto_start_server: false` to `auto_start_server: true`
3. **Restart the client**

**Note**: Auto-start requires the client to find the X-AnyLabeling-Server installation. The server manager looks for it in:
- `../X-AnyLabeling-Server` (relative to X-AnyLabeling)
- `/home/aiserver/LABS/X-ANYLABELING/X-AnyLabeling-Server` (absolute path)

If auto-start doesn't work, manually start the server using the scripts.

## Troubleshooting

### Error: "Server not available: Server is not running and auto-start is disabled"

**Solution**: Start the server manually:

```bash
cd X-AnyLabeling-Install
./start-server.sh
```

Then verify it's running:
```bash
./monitor-server.sh
```

### Error: Connection refused or timeout

**Check 1**: Verify server is running
```bash
cd X-AnyLabeling-Install
./monitor-server.sh
```

**Check 2**: Test server connection
```bash
curl http://localhost:8014/v1/health
```

**Check 3**: Verify server URL in config
```bash
cat X-AnyLabeling/anylabeling/configs/auto_labeling/remote_server.yaml | grep server_url
```

Should show: `server_url: http://localhost:8014`

**Check 4**: Check server logs
```bash
tail -f X-AnyLabeling-Install/logs/server.log
```

### Error: Port already in use

If port 8014 is already in use:

1. **Find what's using the port**:
   ```bash
   lsof -i :8014
   ```

2. **Stop the existing process** or **change the port**:
   - Edit `X-AnyLabeling-Install/.env`:
     ```bash
     PORT=8015
     XANYLABELING_PORT=8015
     ```
   - Update `remote_server.yaml`:
     ```yaml
     server_url: http://localhost:8015
     ```
   - Restart both server and client

### Server starts but client can't connect

1. **Check firewall**: Ensure port 8014 is not blocked
2. **Check server host**: If connecting from another machine, ensure server uses `0.0.0.0` not `127.0.0.1`
3. **Check server logs**: Look for errors in `logs/server.log`
4. **Verify models are loaded**: 
   ```bash
   curl http://localhost:8014/v1/models
   ```

## Manual Server Start (Alternative)

If you prefer to start the server manually without scripts:

```bash
# Activate virtual environment
cd X-AnyLabeling-Install
source venv-server/bin/activate

# Start server
cd ../X-AnyLabeling-Server
uvicorn app.main:app --host 0.0.0.0 --port 8014
```

Or in background:
```bash
cd X-AnyLabeling-Install
source venv-server/bin/activate
cd ../X-AnyLabeling-Server
nohup uvicorn app.main:app --host 0.0.0.0 --port 8014 > ../X-AnyLabeling-Install/logs/server.log 2>&1 &
```

## Complete Workflow Example

```bash
# 1. Navigate to install directory
cd X-AnyLabeling-Install

# 2. Start server
./start-server.sh

# 3. Verify server is running
./monitor-server.sh

# 4. Start client (in another terminal or after server starts)
./start-client.sh

# 5. Or use combined script to start both
./start-all.sh

# 6. Monitor both services
./monitor-all.sh
```

## Using Remote Models

Once connected, you can use server-hosted models:

1. **Segment Anything 3 (SAM3)**:
   - Select **Remote-Server** → **Segment Anything 3**
   - Use text prompts: `person, car, bicycle`
   - Or use visual prompts: Draw bounding boxes with `+Rect` or `-Rect`

2. **Other available models**:
   - Check what models are loaded:
     ```bash
     curl http://localhost:8014/v1/models
     ```

## Additional Resources

- **Server Management**: See `README.md` for complete script documentation
- **Server Documentation**: [X-AnyLabeling-Server](https://github.com/CVHub520/X-AnyLabeling-Server)
- **Client Documentation**: [X-AnyLabeling](https://github.com/CVHub520/X-AnyLabeling)

