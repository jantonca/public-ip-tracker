#!/bin/sh

# Import dependencies
. "$(dirname "$0")/log.sh"

# Email functionality
MAIL_LAST_SENT_FILE="$DATA_DIR/last_email.txt"
MIN_EMAIL_INTERVAL="${MIN_EMAIL_INTERVAL:-300}"  # 5 minutes default

# Check if msmtp is properly configured
check_email_config() {
    if [ ! -f "/etc/msmtprc" ]; then
        log_error "msmtp configuration file missing"
        return 1
    fi

    # Check if msmtp is installed
    if ! command -v msmtp >/dev/null 2>&1; then
        log_error "msmtp is not installed"
        return 1
    fi

    # Check permissions on msmtprc
    if [ "$(stat -c %a /etc/msmtprc)" != "600" ]; then
        log_warn "Incorrect permissions on /etc/msmtprc. Setting to 600..."
        chmod 600 /etc/msmtprc
    fi

    return 0
}

# Get system information for email
get_system_info() {
    {
        echo "System Information:"
        echo "-------------------"
        echo "Hostname: $(hostname)"
        echo "Date: $(date)"
        echo "Uptime: $(uptime)"
        echo "IP Check Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        
        # Memory usage
        echo -e "\nMemory Usage:"
        free -h | awk 'NR==1{print $1,$2,$3,$4} NR==2{print $1,$2,$3,$4}'
        
        # Disk usage
        echo -e "\nDisk Usage:"
        df -h / | awk 'NR==1{print $1,$2,$3,$4,$5,$6} NR==2{print $1,$2,$3,$4,$5,$6}'
    } 2>/dev/null
}

# Rate limit check for email sending
can_send_email() {
    local current_time
    current_time=$(date +%s)
    local last_sent=0
    
    if [ -f "$MAIL_LAST_SENT_FILE" ]; then
        last_sent=$(cat "$MAIL_LAST_SENT_FILE" 2>/dev/null || echo "0")
    fi
    
    if [ $((current_time - last_sent)) -ge "$MIN_EMAIL_INTERVAL" ]; then
        return 0
    else
        log_debug "Email sending skipped due to rate limiting (interval: $MIN_EMAIL_INTERVAL seconds)"
        return 1
    fi
}

# Update last email sent time
update_last_email_time() {
    date +%s > "$MAIL_LAST_SENT_FILE"
}

# Send email with retries and proper formatting
send_email() {
    local subject="$1"
    local body="$2"
    local attempt=1
    
    # Check email configuration
    check_email_config || return 1
    
    # Check rate limiting
    can_send_email || return 0
    
    # Get system information
    local sys_info
    sys_info="$(get_system_info)"
    
    # Prepare email content with HTML formatting
    local email_content="Subject: $subject
Content-Type: text/html; charset=UTF-8
From: IP Tracker <$EMAIL_RECIPIENT>
To: $EMAIL_RECIPIENT

<html>
<body style='font-family: Arial, sans-serif;'>
    <h2 style='color: #2c3e50;'>IP Tracker Notification</h2>
    <div style='background-color: #f8f9fa; padding: 15px; border-radius: 5px;'>
        <p style='color: #34495e;'>$body</p>
    </div>
    <hr style='border-top: 1px solid #eee;'>
    <pre style='font-size: 12px; color: #666;'>
$sys_info
    </pre>
    <p style='font-size: 12px; color: #666;'>
        This is an automated message from IP Tracker.
        <br>
        Generated on: $(date '+%Y-%m-%d %H:%M:%S %Z')
    </p>
</body>
</html>"

    # Try to send email with retries
    while [ "$attempt" -le "${RETRY_ATTEMPTS:-2}" ]; do
        if printf "%s" "$email_content" | msmtp "$EMAIL_RECIPIENT"; then
            log_info "Email notification sent successfully"
            update_last_email_time
            return 0
        fi
        
        log_warn "Email attempt $attempt failed..."
        attempt=$((attempt + 1))
        
        if [ "$attempt" -le "${RETRY_ATTEMPTS:-2}" ]; then
            sleep "${RETRY_DELAY:-3}"
        fi
    done
    
    log_error "Failed to send email after ${RETRY_ATTEMPTS:-2} attempts"
    return 1
}

# Function to send IP change notification
notify_ip_change() {
    local message="$1"
    local subject="[IP Tracker] IP Address Change Detected"
    
    send_email "$subject" "$message"
}

# Function to send error notification
notify_error() {
    local error_message="$1"
    local subject="[IP Tracker] Error Alert"
    
    send_email "$subject" "Error: $error_message"
}

# Function to send test email
send_test_email() {
    local subject="[IP Tracker] Test Email"
    local message="This is a test email from IP Tracker. If you receive this, email sending is configured correctly."
    
    send_email "$subject" "$message"
}