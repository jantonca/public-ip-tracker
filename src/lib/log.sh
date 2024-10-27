#!/bin/sh

# Logging functionality
LOG_FILE="$LOG_DIR/ip-tracker.log"
MAX_LOG_SIZE=1048576  # 1MB in bytes

# Logging levels
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3

# Current log level (can be overridden in config)
CURRENT_LOG_LEVEL=${LOG_LEVEL:-1}  # Default to INFO

# Convert log level name to number
get_log_level() {
    case "$1" in
        "DEBUG") echo $LOG_LEVEL_DEBUG ;;
        "INFO")  echo $LOG_LEVEL_INFO ;;
        "WARN")  echo $LOG_LEVEL_WARN ;;
        "ERROR") echo $LOG_LEVEL_ERROR ;;
        *)       echo $LOG_LEVEL_INFO ;;  # Default to INFO
    esac
}

# Check if we should log at this level
should_log() {
    local level_num
    level_num=$(get_log_level "$1")
    [ "$level_num" -ge "$CURRENT_LOG_LEVEL" ]
}

# Rotate log if needed
rotate_log() {
    if [ -f "$LOG_FILE" ]; then
        local size
        size=$(stat -c%s "$LOG_FILE" 2>/dev/null)
        if [ "$size" -gt "$MAX_LOG_SIZE" ]; then
            local backup_file="$LOG_FILE.$(date +%Y%m%d-%H%M%S).gz"
            gzip -c "$LOG_FILE" > "$backup_file"
            : > "$LOG_FILE"
            echo "$(date '+%Y-%m-%d %H:%M:%S'): [INFO] Log rotated to $backup_file" >> "$LOG_FILE"
        fi
    fi
}

# Base logging function
log_message() {
    local level="$1"
    local message="$2"
    
    # Check if we should log at this level
    should_log "$level" || return 0
    
    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Create timestamp
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Write log entry
    printf '%s: [%s] %s\n' "$timestamp" "$level" "$message" >> "$LOG_FILE"
    
    # Rotate log if needed
    rotate_log
}

# Convenience logging functions
log_debug() {
    log_message "DEBUG" "$1"
}

log_info() {
    log_message "INFO" "$1"
}

log_warn() {
    log_message "WARN" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

# Function to clean up old log files
cleanup_old_logs() {
    find "$LOG_DIR" -name "ip-tracker.log.*.gz" -type f -mtime +30 -delete 2>/dev/null
    log_debug "Cleaned up old log files"
}

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    
    # Set initial log entry
    log_info "Logging initialized"
    
    # Clean up old logs if needed
    if [ ! -f "$LOG_DIR/.cleanup_marker" ] || ! find "$LOG_DIR/.cleanup_marker" -mtime -1 | grep -q .; then
        cleanup_old_logs
        touch "$LOG_DIR/.cleanup_marker"
    fi
}