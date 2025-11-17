#!/bin/bash

# Script to start the INRI miner with port checking before launching Docker container

# Function to check if a port is available
check_port() {
    local port=$1
    if netstat -tuln | grep -q ":$port "; then
        return 1  # Port busy
    else
        return 0  # Port free
    fi
}

# Function to find an available port starting from a base port
find_available_port() {
    local base_port=$1
    local port=$base_port
    
    while ! check_port $port; do
        echo "[~] Port $port busy, trying $((port+1))..." >&2
        port=$((port+1))
        
        # Safety to avoid infinite loop
        if [ $port -gt $((base_port+1000)) ]; then
            echo "[!] Unable to find available port after 1000 attempts" >&2
            exit 1
        fi
    done
    
    echo $port
}

# Stop and remove existing container if it exists
# This should be done BEFORE checking port availability to free up any ports in use
if docker ps -a --format '{{.Names}}' | grep -q '^inri-miner$'; then
    echo "[~] Stopping existing container..." >&2
    docker stop inri-miner >/dev/null 2>&1
    echo "[~] Removing existing container..." >&2
    docker rm inri-miner >/dev/null 2>&1
fi

# Default ports
DEFAULT_HTTP_PORT=8545
DEFAULT_WS_PORT=8546
DEFAULT_NETWORK_PORT=30303

# Find available ports
echo "[~] Checking port availability..." >&2

# Find HTTP port
HTTP_PORT=$(find_available_port $DEFAULT_HTTP_PORT)

# Find WebSocket port (different from HTTP port)
WS_PORT=$HTTP_PORT
while [ $WS_PORT -eq $HTTP_PORT ]; do
    WS_PORT=$(find_available_port $((WS_PORT + 1)))
done

# Find Network port (different from HTTP and WebSocket ports)
NETWORK_PORT=$HTTP_PORT
while [ $NETWORK_PORT -eq $HTTP_PORT ] || [ $NETWORK_PORT -eq $WS_PORT ]; do
    NETWORK_PORT=$(find_available_port $((NETWORK_PORT + 1)))
done

# Show selected ports
echo "[✓] Using ports:" >&2
echo "  HTTP Port: $HTTP_PORT" >&2
echo "  WebSocket Port: $WS_PORT" >&2
echo "  Network Port: $NETWORK_PORT" >&2

# Build the Docker image if it doesn't exist
if [[ "$(docker images -q inri-miner 2> /dev/null)" == "" ]]; then
    echo "[~] Building Docker image..." >&2
    docker build -t inri-miner .
fi

# Start the container with the available ports
echo "[~] Starting INRI miner container..." >&2
docker run -d \
  --name inri-miner \
  -p $HTTP_PORT:8545 \
  -p $WS_PORT:8546 \
  -p $NETWORK_PORT:30303 \
  -p $NETWORK_PORT:30303/udp \
  -e WALLET=$WALLET \
  -e MINER_THREADS=$MINER_THREADS \
  -v inri-data:/root/inri \
  inri-miner

echo "[✓] INRI miner started successfully!" >&2
echo "View logs with: docker logs -f inri-miner" >&2
