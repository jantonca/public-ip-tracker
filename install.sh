#!/bin/sh

# Installation script for Public IP Tracker

# Base directory for installation
INSTALL_DIR="/root/public-ip-tracker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Print colored message
print_message() {
    local color="$1"
    local message="$2"
    printf "%b%s%b\n" "$color" "$message" "$NC"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    print_message "$RED" "Error: This script must be run as root"
    exit 1
fi

# Install required packages
print_message "$YELLOW" "Installing required packages..."
apk update
apk add --no-cache curl msmtp

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Copy files
cp -r src/* "$INSTALL_DIR/"
cp -r config/* "$INSTALL_DIR/config/"

# Set permissions
chmod +x "$INSTALL_DIR/ip-tracker.sh"
chmod +x "$INSTALL_DIR/lib/"*.sh

# Create var directory structure
mkdir -p "$INSTALL_DIR/var/log" "$INSTALL_DIR/var/data"
chmod 755 "$INSTALL_DIR/var"
chmod 755 "$INSTALL_DIR/var/log"
chmod 755 "$INSTALL_DIR/var/data"

# Create configuration if it doesn't exist
if [ ! -f "$INSTALL_DIR/config/config" ]; then
    cp "$INSTALL_DIR/config/config.default" "$INSTALL_DIR/config/config"
    print_message "$YELLOW" "Please edit $INSTALL_DIR/config/config with your settings"
fi

# Create msmtp configuration if it doesn't exist
if [ ! -f "/etc/msmtprc" ]; then
    cp "$INSTALL_DIR/config/msmtp.default" "/etc/msmtprc"
    chmod 600 /etc/msmtprc
    print_message "$YELLOW" "Please edit /etc/msmtprc with your email settings"
fi

# Set up cron job
if ! crontab -l | grep -q "ip-tracker.sh"; then
    (crontab -l 2>/dev/null; echo "*/5 * * * * $INSTALL_DIR/ip-tracker.sh") | crontab -
    print_message "$GREEN" "Added cron job"
fi

print_message "$GREEN" "Installation completed successfully!"
print_message "$YELLOW" "Next steps:"
print_message "$YELLOW" "1. Edit $INSTALL_DIR/config/config"
print_message "$YELLOW" "2. Edit /etc/msmtprc with your email settings"
print_message "$YELLOW" "3. Test the installation by running: $INSTALL_DIR/ip-tracker.sh"