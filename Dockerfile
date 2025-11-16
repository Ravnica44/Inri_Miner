FROM ubuntu:20.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    nano \
    jq \
    tar \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Geth 1.10.26
ENV GETH_VERSION="1.10.26"
ENV GETH_URL="https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.10.26-e5eb32ac.tar.gz"

WORKDIR /tmp
RUN wget -q --show-progress "$GETH_URL" \
    && tar -xzf geth-linux-amd64-1.10.26-e5eb32ac.tar.gz \
    && cp geth-linux-amd64-1.10.26-e5eb32ac/geth /usr/bin/ \
    && chmod +x /usr/bin/geth \
    && rm -rf geth-linux-amd64-1.10.26-e5eb32ac*

# Create data directory
ENV DATADIR="/root/inri"
RUN mkdir -p $DATADIR

# Expose ports
EXPOSE 8545 8546 30303 30303/udp

# Copy startup script
COPY start-miner.sh /usr/local/bin/start-miner.sh
RUN chmod +x /usr/local/bin/start-miner.sh

ENTRYPOINT ["/usr/local/bin/start-miner.sh"]