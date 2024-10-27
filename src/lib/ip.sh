#!/bin/sh

# Import dependencies
. "$(dirname "$0")/log.sh"

# IP management functionality
LAST_IP_FILE="$DATA_DIR/last_ip.txt"

# Get current IP with fallback providers
get_current_ip() {
    local ip=""
    local provider
    local start_time
    start_time=$(date +%s)
    
    for provider in $IP_PROVIDERS; do
        local attempt=1
        while [ "$attempt" -le "${RETRY_ATTEMPTS:-2}" ]; do
            ip=$(curl -s --max-time 10 "$provider")
            if [ -n "$ip" ] && echo "$ip" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' >/dev/null; then
                log_debug "Got IP $ip from $provider in $(($(date +%s) - start_time)) seconds"
                echo "$ip"
                return 0
            fi
            log_warn "Failed to get IP from $provider (attempt $attempt)"
            attempt=$((attempt + 1))
            [ "$attempt" -le "${RETRY_ATTEMPTS:-2}" ] && sleep "${RETRY_DELAY:-3}"
        done
    done
    
    log_error "Failed to get IP from all providers"
    return 1
}

# Get last known IP
get_last_ip() {
    if [ -f "$LAST_IP_FILE" ]; then
        cat "$LAST_IP_FILE" 2>/dev/null || {
            log_warn "Failed to read last IP, assuming none"
            echo ""
        }
    else
        echo ""
    fi
}

# Save current IP
save_current_ip() {
    if echo "$1" > "$LAST_IP_FILE"; then
        log_debug "Saved new IP $1 to file"
        return 0
    else
        log_error "Failed to save IP $1 to file"
        return 1
    fi
}

# Compare and handle IP change
handle_ip_change() {
    local current_ip="$1"
    local last_ip="$2"
    
    if [ "$current_ip" != "$last_ip" ]; then
        local message="Public IP changed from ${last_ip:-'(none)'} to $current_ip"
        log_info "$message"
        notify_ip_change "$message"
        save_current_ip "$current_ip"
    else
        log_debug "No change in public IP: $current_ip"
    fi
}