# INRI Chain Miner Docker

This repository contains Docker configuration files to run the INRI Chain miner node using Docker containers instead of systemd.

## Prerequisites

- Docker
- Docker Compose
- net-tools (for port checking)

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd inri-miner-docker
   ```

2. Make the startup scripts executable:
   ```bash
   chmod +x start-miner.sh
   chmod +x start-miner-with-port-check.sh
   ```

## Configuration

Before starting the miner, you need to set your wallet address:

```bash
export WALLET="0xYourWalletAddress"
```

Optionally, you can set the number of mining threads:
```bash
export MINER_THREADS=4
```

## Usage

### Using the Port Checking Script (Recommended)

This script automatically checks for available ports and starts the miner:

```bash
./start-miner-with-port-check.sh
```

### Using Docker Compose (Standard Method)

1. Build and start the container:
   ```bash
   docker-compose up -d
   ```

2. View logs:
   ```bash
   docker-compose logs -f
   ```

3. Stop the miner:
   ```bash
   docker-compose down
   ```

### Using Docker Directly

1. Build the image:
   ```bash
   docker build -t inri-miner .
   ```

2. Run the container:
   ```bash
   docker run -d \
     --name inri-miner \
     -p 8545:8545 \
     -p 8546:8546 \
     -p 30303:30303 \
     -p 30303:30303/udp \
     -e WALLET=$WALLET \
     -e MINER_THREADS=$MINER_THREADS \
     inri-miner
   ```

3. View logs:
   ```bash
   docker logs -f inri-miner
   ```

4. Stop and remove the container:
   ```bash
   docker stop inri-miner
   docker rm inri-miner
   ```

## Ports

The following ports are used by the miner:

- `8545`: HTTP RPC
- `8546`: WebSocket RPC
- `30303`: P2P network (TCP and UDP)

If these ports are already in use, the port checking script will automatically find available ports.

## Data Persistence

Blockchain data is stored in a Docker volume named `inri-data` to persist data between container restarts.

## Troubleshooting

If you encounter issues:

1. Check that your wallet address is correctly set and formatted
2. Verify that the required ports are available on your system
3. Check the container logs for error messages
4. Ensure net-tools is installed for port checking functionality

## JavaScript Console Commands

### Connecting to Geth Console

```bash
# Attach to the running node console
docker exec -it inri-miner geth attach /root/inri/geth.ipc
```

### Useful JavaScript Commands

#### Balance Check
```javascript
// Check your wallet balance
eth.getBalance("0xYourWalletAddress")

// Convert to ethers (if it's in wei)
web3.fromWei(eth.getBalance("0xYourWalletAddress"), "ether")
```

#### Block Information
```javascript
// Latest block number
eth.blockNumber

// Details of the latest block
eth.getBlock("latest")

// Latest block number (readable format)
eth.getBlockByNumber("latest").number

// Miner address of the latest block
eth.getBlockByNumber("latest").miner
```

#### Check if your address is the miner
```javascript
// Compare miner address with yours
eth.getBlockByNumber("latest").miner === "0xYourWalletAddress"
```

#### Get list of blocks mined by your address
```javascript
var yourAddress = "0xYourWalletAddress", lastBlock = eth.blockNumber, minedBlocks = []; for (var i = 0; i <= lastBlock; i++) { var block = eth.getBlock(i); if (block.miner.toLowerCase() === yourAddress.toLowerCase()) { minedBlocks.push(block.number); } } minedBlocks
```

#### Count mined blocks
```javascript
var count = 0; var yourAddress = "0xYourWalletAddress"; var lastBlock = eth.blockNumber; for (var i = 0; i <= lastBlock; i++) { var block = eth.getBlock(i); if (block.miner.toLowerCase() === yourAddress.toLowerCase()) { count++; } } count
```

#### Exit the console
```javascript
exit
```