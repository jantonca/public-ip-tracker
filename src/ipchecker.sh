#!/bin/sh

# Resolve script location
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
LIB_DIR="$SCRIPT_DIR/lib"

# Import dependencies
. "$LIB_DIR/config.sh"
. "$LIB_DIR/ip.sh"
. "$LIB_DIR/email.sh"
. "$LIB_DIR/health.sh"
. "$LIB_DIR/cloudflare.sh"

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
    if [ "$current_ip" != "$last_ip" ]; then
        log_info "IP change detected: $last_ip -> $current_ip"
        
        # Update Cloudflare if enabled
        if [ "${CLOUDFLARE_ENABLED:-false}" = "true" ]; then
            if validate_cloudflare_config; then
                update_cloudflare_dns "$current_ip" "$last_ip"
            else
                log_error "Invalid Cloudflare configuration"
            fi
        fi
        
        # Send email notification
        notify_ip_change "Public IP changed from ${last_ip:-'(none)'} to $current_ip"
        
        # Save new IP
        save_current_ip "$current_ip"
    else
        log_debug "No IP change detected. Current IP: $current_ip"
    fi

    # Perform cleanup
    cleanup_old_logs
}

# Run main function
main "$@"