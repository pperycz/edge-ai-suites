#!/bin/bash

# Path to the .env file
ENV_FILE="./.env"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found."
    exit 1
fi

# Update the HOST_IP in .env file
export HOST_IP="${1:-$(hostname -I | cut -f1 -d' ')}"
echo "Configuring application to use $HOST_IP"
if grep -q "^HOST_IP=" "$ENV_FILE"; then
    # Replace existing HOST_IP line
    sed -i "s/^HOST_IP=.*/HOST_IP=$HOST_IP/" "$ENV_FILE"
else
    # Add HOST_IP if it doesn't exist
    echo "HOST_IP=$HOST_IP" >> "$ENV_FILE"
fi

# Extract SAMPLE_APP variable from .env file
SAMPLE_APP=$(grep -E "^SAMPLE_APP=" "$ENV_FILE" | cut -d '=' -f2 | tr -d '"' | tr -d "'")

# Check if SAMPLE_APP variable exists
if [ -z "$SAMPLE_APP" ]; then
    echo "Error: SAMPLE_APP variable not found in .env file."
    exit 1
fi

# Check if the directory exists
if [ ! -d "$SAMPLE_APP" ]; then
    echo "Error: Directory $SAMPLE_APP does not exist."
    exit 1
fi

# Navigate to the directory and run the install script
echo "Navigating to $SAMPLE_APP directory and running install script..."
cd "$SAMPLE_APP" || exit 1

if [ -f "./install.sh" ]; then
    chmod +x ./install.sh
    ./install.sh $HOST_IP
else
    echo "Error: install.sh not found in $SAMPLE_APP directory."
    exit 1
fi