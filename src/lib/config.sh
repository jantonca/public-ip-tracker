#!/bin/sh

# Configuration management

# Base paths
BASE_DIR="$(dirname "$(dirname "$(dirname "$0")")")"
CONFIG_DIR="$BASE_DIR/config"
VAR_DIR="$BASE_DIR/var"
LOG_DIR="$VAR_DIR/log"
DATA_DIR="$VAR_DIR/data"

# Configuration files
CONFIG_FILE="$CONFIG_DIR/config"
CONFIG_DEFAULT="$CONFIG_DIR/config.default"

# Load configuration
load_config() {
    # Create necessary directories
    mkdir -p "$LOG_DIR" "$DATA_DIR"
    
    # If config doesn't exist, copy default
    if [ ! -f "$CONFIG_FILE" ]; then
        if [ -f "$CONFIG_DEFAULT" ]; then
            cp "$CONFIG_DEFAULT" "$CONFIG_FILE"
        else
            echo "Error: Default configuration file not found"
            exit 1
        fi
    fi
    
    # Source the configuration
    . "$CONFIG_FILE"
    
    # Export common variables
    export BASE_DIR CONFIG_DIR VAR_DIR LOG_DIR DATA_DIR
}

# Validate configuration
validate_config() {
    local missing=""
    
    # Required variables
    for var in TZ IP_PROVIDERS EMAIL_RECIPIENT; do
        if [ -z "$(eval echo \$$var)" ]; then
            missing="${missing}${var} "
        fi
    done
    
    if [ -n "$missing" ]; then
        echo "Error: Missing required configuration variables: ${missing}"
        exit 1
    fi
}

# Initialize configuration
init_config() {
    load_config
    validate_config
}