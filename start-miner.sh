#!/bin/bash

# Script to start the INRI miner in a Docker container

# Environment variables expected:
# WALLET: Ethereum wallet address
# NETWORK_ID: Network ID (default 3777)
# HTTP_PORT: HTTP port (default 8545)
# WS_PORT: WebSocket port (default 8546)
# NETWORK_PORT: Network port (default 30303)
# MINER_THREADS: Number of mining threads (default calculated based on CPU cores)
# BOOTNODES: Bootnodes enodes

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

# Default values
NETWORK_ID=${NETWORK_ID:-3777}
HTTP_PORT=${HTTP_PORT:-8545}
WS_PORT=${WS_PORT:-8546}
NETWORK_PORT=${NETWORK_PORT:-30303}
DATADIR="/root/inri"
BOOTNODES=${BOOTNODES:-"enode://5c7c744a9ac53fdb9e529743208ebd123f11c73d973aa2cf653f3ac1bdf460b6f2a9b2aec23b8f2b9d692d8c898fe0e93dac8d7533db8926924e770969f3a46a@134.199.203.8:30303"}

# Check wallet address
if [[ -z "$WALLET" ]]; then
    echo "[!] Wallet address is required"
    echo "Please set the WALLET environment variable"
    exit 1
fi

if [[ ! $WALLET =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    echo "[!] Invalid wallet address format!"
    exit 1
fi

# Calculate mining threads
CPU_CORES=$(nproc)
MINER_THREADS=${MINER_THREADS:-$((CPU_CORES / 2))}
[ $MINER_THREADS -lt 1 ] && MINER_THREADS=1

# Download genesis file if needed
if [ ! -f "$DATADIR/genesis.json" ]; then
    echo "[~] Downloading genesis file..." >&2
    mkdir -p $DATADIR
    curl -fSLo "$DATADIR/genesis.json" "https://rpc.inri.life/genesis.json" 2>/dev/null
    
    # Initialize blockchain
    echo "[~] Initializing blockchain..." >&2
    geth --datadir "$DATADIR" init "$DATADIR/genesis.json" >/dev/null 2>&1
fi

# Find available ports
echo "[~] Checking port availability..." >&2
HTTP_PORT=$(find_available_port $HTTP_PORT)
WS_PORT=$(find_available_port $WS_PORT)
NETWORK_PORT=$(find_available_port $NETWORK_PORT)

# Start miner
echo "[✓] Starting INRI miner..." >&2
echo "Wallet: $WALLET" >&2
echo "Mining Threads: $MINER_THREADS" >&2
echo "HTTP Port: $HTTP_PORT" >&2
echo "WebSocket Port: $WS_PORT" >&2
echo "Network Port: $NETWORK_PORT" >&2

exec geth --datadir $DATADIR \
    --networkid $NETWORK_ID \
    --syncmode full \
    --gcmode archive \
    --cache 2048 \
    --maxpeers 50 \
    --http --http.addr 0.0.0.0 --http.port $HTTP_PORT \
    --http.api eth,net,web3,miner,txpool,admin \
    --http.corsdomain "*" --http.vhosts "*" \
    --ws --ws.addr 0.0.0.0 --ws.port $WS_PORT \
    --ws.api eth,net,web3 \
    --port $NETWORK_PORT \
    --bootnodes "$BOOTNODES" \
    --mine --miner.threads $MINER_THREADS --miner.etherbase "$WALLET" \
    --nat none \
    --verbosity 3