#!/bin/sh

# Resolve script location
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LIB_DIR="$SCRIPT_DIR/lib"

# Import dependencies
. "$LIB_DIR/config.sh"
. "$LIB_DIR/ip.sh"
. "$LIB_DIR/email.sh"
. "$LIB_DIR/health.sh"

# Main execution
main() {
    # Initialize configuration
    init_config
    
    # Ensure dependencies
    ensure_dependencies
    
    # Perform health check
    perform_health_check
    
    # Get current IP
    local current_ip
    current_ip=$(get_current_ip)
    if [ $? -ne 0 ]; then
        log_error "Failed to get current IP"
        exit 1
    fi

    # Get last known IP
    local last_ip
    last_ip=$(get_last_ip)

    # Handle IP change
    handle_ip_change "$current_ip" "$last_ip"

    # Perform cleanup
    cleanup_old_logs
}

# Run main function
main "$@"