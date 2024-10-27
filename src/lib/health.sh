#!/bin/sh

# Import dependencies
. "$(dirname "$0")/log.sh"
. "$(dirname "$0")/email.sh"

# Health check thresholds
DISK_THRESHOLD="${DISK_THRESHOLD:-90}"        # Warning if disk usage > 90%
MEMORY_THRESHOLD="${MEMORY_THRESHOLD:-90}"    # Warning if memory usage > 90%
LOAD_THRESHOLD="${LOAD_THRESHOLD:-4}"         # Warning if load average > 4
MAX_LOG_SIZE="${MAX_LOG_SIZE:-10485760}"     # 10MB default max log size
HEALTH_STATUS_FILE="$DATA_DIR/health_status"

# Ensure required tools are installed
ensure_dependencies() {
    local missing_tools=""
    
    for tool in curl msmtp grep awk sed; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools="$missing_tools $tool"
        fi
    done
    
    if [ -n "$missing_tools" ]; then
        log_warn "Missing required tools:$missing_tools"
        log_info "Installing missing dependencies..."
        
        apk update >/dev/null 2>&1
        apk add --no-cache $missing_tools >/dev/null 2>&1
        
        # Verify installation
        for tool in $missing_tools; do
            if ! command -v "$tool" >/dev/null 2>&1; then
                log_error "Failed to install $tool"
                return 1
            fi
        done
    fi
    
    return 0
}

# Check disk space
check_disk_space() {
    local mount_point="$1"
    local usage
    usage=$(df -h "$mount_point" | awk 'NR==2 {print $5}' | tr -d '%')
    
    if [ "$usage" -gt "$DISK_THRESHOLD" ]; then
        log_warn "High disk usage: ${usage}% on $mount_point"
        return 1
    fi
    
    log_debug "Disk usage normal: ${usage}% on $mount_point"
    return 0
}

# Check memory usage
check_memory() {
    local memory_usage
    memory_usage=$(free | awk 'NR==2 {printf "%.0f", $3/$2 * 100}')
    
    if [ "$memory_usage" -gt "$MEMORY_THRESHOLD" ]; then
        log_warn "High memory usage: ${memory_usage}%"
        return 1
    fi
    
    log_debug "Memory usage normal: ${memory_usage}%"
    return 0
}

# Check system load
check_system_load() {
    local load_1min
    load_1min=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
    local load_integer="${load_1min%.*}"
    
    if [ "$load_integer" -gt "$LOAD_THRESHOLD" ]; then
        log_warn "High system load: $load_1min"
        return 1
    fi
    
    log_debug "System load normal: $load_1min"
    return 0
}

# Check log file size
check_log_size() {
    if [ -f "$LOG_FILE" ]; then
        local size
        size=$(stat -c%s "$LOG_FILE" 2>/dev/null)
        
        if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
            log_warn "Log file size ($size bytes) exceeds threshold"
            return 1
        fi
    fi
    
    return 0
}

# Check msmtp configuration
check_mail_config() {
    if [ ! -f "/etc/msmtprc" ]; then
        log_error "msmtp configuration file missing"
        return 1
    fi
    
    if [ "$(stat -c %a /etc/msmtprc)" != "600" ]; then
        log_warn "Incorrect permissions on /etc/msmtprc"
        chmod 600 /etc/msmtprc
    fi
    
    return 0
}

# Check internet connectivity
check_internet() {
    local test_hosts="1.1.1.1 8.8.8.8 google.com"
    local success=false
    
    for host in $test_hosts; do
        if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
            success=true
            break
        fi
    done
    
    if ! $success; then
        log_error "Internet connectivity check failed"
        return 1
    fi
    
    log_debug "Internet connectivity OK"
    return 0
}

# Clean up old files
cleanup_old_files() {
    # Clean up old log files (older than 30 days)
    find "$LOG_DIR" -name "*.gz" -type f -mtime +30 -delete 2>/dev/null
    
    # Clean up old health status files (older than 7 days)
    find "$DATA_DIR" -name "health_status.*" -type f -mtime +7 -delete 2>/dev/null
}

# Save health status
save_health_status() {
    local status="$1"
    echo "$status" > "$HEALTH_STATUS_FILE"
}

# Format health report
format_health_report() {
    {
        echo "Health Check Report"
        echo "==================="
        echo "Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Hostname: $(hostname)"
        echo ""
        
        echo "System Status"
        echo "-------------"
        echo "Uptime: $(uptime)"
        echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
        
        echo ""
        echo "Memory Usage"
        echo "------------"
        free -h
        
        echo ""
        echo "Disk Usage"
        echo "----------"
        df -h /
        
        echo ""
        echo "Network Status"
        echo "--------------"
        if check_internet >/dev/null 2>&1; then
            echo "Internet Connectivity: OK"
        else
            echo "Internet Connectivity: FAIL"
        fi
        
        echo ""
        echo "Service Status"
        echo "--------------"
        echo "msmtp config: $(test -f /etc/msmtprc && echo "Present" || echo "Missing")"
        echo "Log file size: $(stat -c%s "$LOG_FILE" 2>/dev/null || echo "N/A") bytes"
    } 2>/dev/null
}

# Perform comprehensive health check
perform_health_check() {
    local health_issues=0
    local report
    
    log_info "Starting health check..."
    
    # Run all checks
    check_disk_space "/" || health_issues=$((health_issues + 1))
    check_memory || health_issues=$((health_issues + 1))
    check_system_load || health_issues=$((health_issues + 1))
    check_log_size || health_issues=$((health_issues + 1))
    check_mail_config || health_issues=$((health_issues + 1))
    check_internet || health_issues=$((health_issues + 1))
    
    # Generate health report
    report=$(format_health_report)
    
    # Save status
    save_health_status "$health_issues"
    
    # If there are issues, send notification
    if [ "$health_issues" -gt 0 ]; then
        log_warn "Found $health_issues health issue(s)"
        notify_error "Health check found $health_issues issue(s)\n\n$report"
    else
        log_info "Health check passed"
    fi
    
    # Perform cleanup if needed
    cleanup_old_files
    
    return "$health_issues"
}