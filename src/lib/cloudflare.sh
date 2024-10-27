#!/bin/sh

# Import dependencies
. "$(dirname "$0")/log.sh"
. "$(dirname "$0")/email.sh"

# Cloudflare API interaction
update_cloudflare_dns() {
    local ip="$1"
    local old_ip="$2"
    
    # Skip if IPs are the same
    if [ "$ip" = "$old_ip" ]; then
        log_info "Cloudflare: IP ($ip) for ${CLOUDFLARE_RECORD_NAME} has not changed."
        return 0
    }

    # Validate configuration
    if [ -z "$CLOUDFLARE_AUTH_EMAIL" ] || [ -z "$CLOUDFLARE_AUTH_KEY" ] || \
       [ -z "$CLOUDFLARE_ZONE_ID" ] || [ -z "$CLOUDFLARE_RECORD_NAME" ]; then
        log_error "Cloudflare: Missing required configuration"
        return 1
    }

    # Set auth header based on method
    local auth_header
    if [ "${CLOUDFLARE_AUTH_METHOD:-token}" = "global" ]; then
        auth_header="X-Auth-Key:"
    else
        auth_header="Authorization: Bearer"
    fi

    # Get existing DNS record
    log_info "Cloudflare: Checking existing DNS record"
    local record
    record=$(curl -s -X GET \
        "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records?type=A&name=$CLOUDFLARE_RECORD_NAME" \
        -H "X-Auth-Email: $CLOUDFLARE_AUTH_EMAIL" \
        -H "$auth_header $CLOUDFLARE_AUTH_KEY" \
        -H "Content-Type: application/json")

    # Check if record exists
    if echo "$record" | grep -q "\"count\":0"; then
        log_error "Cloudflare: Record does not exist for ${CLOUDFLARE_RECORD_NAME}"
        notify_error "Cloudflare DNS record does not exist for ${CLOUDFLARE_RECORD_NAME}"
        return 1
    fi

    # Extract record identifier
    local record_identifier
    record_identifier=$(echo "$record" | sed -E 's/.*"id":"([A-Za-z0-9_]+)".*/\1/')
    
    if [ -z "$record_identifier" ]; then
        log_error "Cloudflare: Failed to get record identifier"
        return 1
    }

    # Update DNS record
    log_info "Cloudflare: Updating DNS record with new IP: $ip"
    local update
    update=$(curl -s -X PATCH \
        "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$record_identifier" \
        -H "X-Auth-Email: $CLOUDFLARE_AUTH_EMAIL" \
        -H "$auth_header $CLOUDFLARE_AUTH_KEY" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"A\",\"name\":\"$CLOUDFLARE_RECORD_NAME\",\"content\":\"$ip\",\"ttl\":${CLOUDFLARE_TTL:-3600},\"proxied\":${CLOUDFLARE_PROXY:-false}}")

    # Check update status
    if echo "$update" | grep -q "\"success\":false"; then
        log_error "Cloudflare: Failed to update DNS record for $CLOUDFLARE_RECORD_NAME ($ip)"
        notify_error "Cloudflare DNS update failed for $CLOUDFLARE_RECORD_NAME ($ip)"
        return 1
    fi

    # Send notifications if configured
    if [ -n "$CLOUDFLARE_DISCORD_URI" ]; then
        send_discord_notification "$ip"
    fi
    
    if [ -n "$CLOUDFLARE_SLACK_URI" ]; then
        send_slack_notification "$ip"
    fi

    log_info "Cloudflare: Successfully updated DNS record for $CLOUDFLARE_RECORD_NAME to $ip"
    return 0
}

# Send Discord notification
send_discord_notification() {
    local ip="$1"
    local message="$CLOUDFLARE_SITE_NAME Updated: $CLOUDFLARE_RECORD_NAME's new IP Address is $ip"
    
    curl -s -H "Accept: application/json" \
         -H "Content-Type:application/json" \
         -X POST \
         --data "{\"content\":\"$message\"}" \
         "$CLOUDFLARE_DISCORD_URI" >/dev/null
}

# Send Slack notification
send_slack_notification() {
    local ip="$1"
    local message="$CLOUDFLARE_SITE_NAME Updated: $CLOUDFLARE_RECORD_NAME's new IP Address is $ip"
    
    curl -s -L -X POST "$CLOUDFLARE_SLACK_URI" \
         --data-raw "{\"channel\":\"$CLOUDFLARE_SLACK_CHANNEL\",\"text\":\"$message\"}" \
         >/dev/null
}

# Validate Cloudflare configuration
validate_cloudflare_config() {
    local missing=""
    
    # Required variables
    for var in CLOUDFLARE_AUTH_EMAIL CLOUDFLARE_AUTH_KEY CLOUDFLARE_ZONE_ID CLOUDFLARE_RECORD_NAME; do
        if [ -z "$(eval echo \$$var)" ]; then
            missing="${missing}${var} "
        fi
    done
    
    if [ -n "$missing" ]; then
        log_error "Missing required Cloudflare configuration variables: ${missing}"
        return 1
    fi
    
    return 0
}