# Public IP Tracker

A lightweight and efficient public IP monitoring system designed for Alpine Linux and LXC containers. This tool tracks changes in your public IP address, updates Cloudflare DNS records, and sends notifications through multiple channels (email, Slack, Discord).

## 🌟 Features

- 📡 Real-time public IP address monitoring
- 📧 Email notifications for IP changes
- ☁️ Cloudflare DNS integration
- 🔔 Multiple notification channels (Email, Slack, Discord)
- 🔄 Multiple IP providers with failback system
- 📊 System health monitoring
- 📝 Efficient logging with rotation
- 🔒 Secure credential handling
- 🏃‍♂️ Low resource usage
- 🐳 Optimized for Alpine Linux and LXC containers

## 📋 Prerequisites

- Alpine Linux (tested on version 3.x)
- Root access
- Basic system utilities (provided by BusyBox)
- Internet connection
- Gmail account or SMTP server (for email notifications)
- Cloudflare account (optional, for DNS updates)
- Slack/Discord webhooks (optional, for additional notifications)

## 🔧 Installation

### Quick Install

```bash
# Update package list and install git
apk update
apk add git

# Clone the repository
cd /root
git clone https://github.com/yourusername/public-ip-tracker.git
cd public-ip-tracker

# Run installation script
chmod +x install.sh
./install.sh
```

### Manual Installation

1. Install required packages:

```bash
apk update
apk add curl msmtp git
```

2. Clone the repository:

```bash
cd /root
git clone https://github.com/yourusername/public-ip-tracker.git
cd public-ip-tracker
```

3. Create configuration files:

```bash
cp config/config.default config/config
cp config/msmtp.default /etc/msmtprc
```

4. Set proper permissions:

```bash
chmod 600 /etc/msmtprc
chmod +x src/ip-tracker.sh
chmod +x src/lib/*.sh
```

5. Create required directories:

```bash
mkdir -p var/log var/data
chmod 755 var var/log var/data
```

## ⚙️ Configuration Guide

### Required Configuration

These settings are mandatory for the basic functionality (IP tracking and email notifications):

```bash
# Required Email Settings
EMAIL_RECIPIENT="your-email@domain.com"    # Where notifications will be sent
TZ="Australia/Sydney"                      # Your timezone

# Required SMTP Configuration (/etc/msmtprc)
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           your-email@gmail.com
user           your-email@gmail.com
password       your-app-specific-password

account default : gmail
```

### Optional Features

#### 1. System Monitoring Thresholds

Optional settings for health checks. If not set, defaults will be used.

```bash
# System monitoring (optional, showing default values)
DISK_THRESHOLD=90            # Disk usage warning threshold (%)
MEMORY_THRESHOLD=90         # Memory usage warning threshold (%)
LOAD_THRESHOLD=4           # System load warning threshold
VERBOSE_LOGGING=false      # Enable detailed logging
LOG_LEVEL=INFO            # Logging level (DEBUG, INFO, WARN, ERROR)
```

#### 2. Cloudflare Integration (Optional)

Required only if you want to update Cloudflare DNS records:

```bash
# Enable Cloudflare integration
CLOUDFLARE_ENABLED=true                          # Set to true to enable

# Required for Cloudflare (if enabled)
CLOUDFLARE_AUTH_EMAIL="your-email@domain.com"    # Cloudflare login email
CLOUDFLARE_AUTH_METHOD="token"                   # Use "token" or "global"
CLOUDFLARE_AUTH_KEY="your-api-key-or-token"     # API Token or Global Key
CLOUDFLARE_ZONE_ID="your-zone-id"               # Found in Domain Overview
CLOUDFLARE_RECORD_NAME="your.domain.com"        # DNS record to update

# Optional Cloudflare settings (showing defaults)
CLOUDFLARE_TTL=3600                             # DNS record TTL
CLOUDFLARE_PROXY=false                          # Cloudflare proxy status
CLOUDFLARE_SITE_NAME="Your Site Name"           # Used in notifications
```

To find your Cloudflare credentials:

1. Zone ID: Dashboard → Domain → Overview → Zone ID
2. API Token: Dashboard → Profile → API Tokens → Create Token
3. Global API Key: Dashboard → Profile → API Tokens → View Global API Key

#### 3. Additional Notifications (Optional)

Configure these only if you want Slack or Discord notifications:

```bash
# Slack notifications (optional)
CLOUDFLARE_SLACK_CHANNEL="#your-channel"        # Include the # symbol
CLOUDFLARE_SLACK_URI="https://hooks.slack.com/services/xxx"

# Discord notifications (optional)
CLOUDFLARE_DISCORD_URI="https://discord.com/api/webhooks/xxx"
```

#### 4. Advanced Settings (Optional)

Fine-tune the behavior of the script:

```bash
# Performance settings (optional, showing defaults)
MAX_LOG_SIZE=1048576                # Max log size before rotation (1MB)
RETRY_ATTEMPTS=2                    # Number of retry attempts
RETRY_DELAY=3                       # Seconds between retries
LOG_RETENTION_DAYS=30               # Days to keep old logs

# Debug settings (optional)
DEBUG_MODE=false                    # Enable debug output
ENABLE_PROFILING=false             # Enable performance profiling
SAVE_HEALTH_REPORTS=true           # Save detailed health reports
```

### Configuration Priority

1. **Must Configure**:

   - Email recipient (`EMAIL_RECIPIENT`)
   - Timezone (`TZ`)
   - SMTP settings in `/etc/msmtprc`

2. **Recommended to Review**:

   - System monitoring thresholds
   - Log settings
   - Retry settings

3. **Optional Features**:
   - Cloudflare DNS updates
   - Slack notifications
   - Discord notifications
   - Debug settings

### Quick Start Configurations

#### Minimal Working Setup

```bash
# In config/config
EMAIL_RECIPIENT="your-email@domain.com"
TZ="Australia/Sydney"

# In /etc/msmtprc
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

account        gmail
host           smtp.gmail.com
port           587
from           your-email@gmail.com
user           your-email@gmail.com
password       your-app-specific-password

account default : gmail
```

#### 📝 Note for Gmail Users

1. Enable 2-Step Verification in your Google Account
2. Generate an App Password:
   - Go to Google Account Settings
   - Security → App Passwords
   - Select "Mail" and your device
   - Use the generated 16-character password

## 🚀 Usage

### Manual Operation

Run the script manually:

```bash
/root/public-ip-tracker/src/ip-tracker.sh
```

### Automatic Operation

The installation script automatically creates a cron job that runs every 5 minutes. To modify the schedule:

```bash
crontab -e
```

Default cron entry:

```
*/5 * * * * /root/public-ip-tracker/src/ip-tracker.sh
```

### Testing

1. Test email configuration:

```bash
echo "Test email" | msmtp your-email@domain.com
```

2. Test IP checking:

```bash
curl -s https://api.ipify.org
```

3. Test the full script:

```bash
/root/public-ip-tracker/src/ip-tracker.sh
```

## 📁 Directory Structure

```
public-ip-tracker/
├── config/
│   ├── config.default     # Default configuration template
│   └── msmtp.default      # Default email configuration template
├── src/
│   ├── ip-tracker.sh      # Main script
│   └── lib/
│       ├── config.sh      # Configuration management
│       ├── email.sh       # Email functionality
│       ├── ip.sh          # IP checking functionality
│       ├── log.sh         # Logging functionality
│       └── health.sh      # Health check functionality
└── var/                   # Runtime data (created during installation)
    ├── log/               # Log files
    └── data/              # Application data
```

## 🔐 Security Considerations

### API Tokens and Credentials

- Use Cloudflare API Tokens instead of Global API Keys when possible
- Store configuration files with restricted permissions (600)
- Use app-specific passwords for Gmail
- Regularly rotate credentials

### File Permissions

```bash
# Verify correct permissions
chmod 600 /etc/msmtprc
chmod 600 config/config
chmod 755 src/ip-tracker.sh
```

## 📊 Monitoring and Maintenance

### Log Files

View the main log:

```bash
tail -f /root/public-ip-tracker/var/log/ip-tracker.log
```

### Health Checks

The script automatically performs health checks, monitoring:

- Disk usage
- Memory usage
- System load
- Internet connectivity
- Email configuration
- Log file sizes

### Maintenance

Clean up old logs:

```bash
find /root/public-ip-tracker/var/log -name "*.gz" -mtime +30 -delete
```

## 🔄 Updating

Update to the latest version:

```bash
cd /root/public-ip-tracker
git pull
./install.sh
```

## 🚨 Troubleshooting

### Common Issues

1. Email notifications not working:

   - Check /etc/msmtprc permissions (should be 600)
   - Verify email credentials
   - Test email sending manually

2. IP checking fails:

   - Check internet connectivity
   - Verify curl installation
   - Test IP providers manually

3. Script not running automatically:
   - Check cron service: `rc-service crond status`
   - Verify cron entry: `crontab -l`
   - Check script permissions

### Cloudflare Issues

1. API Token not working:

   - Verify token has correct permissions
   - Check Zone ID matches domain
   - Ensure record exists in Cloudflare

2. DNS not updating:
   - Check API response in logs
   - Verify record name matches exactly
   - Confirm proxy setting

### Notification Issues

1. Slack not working:

   - Verify webhook URL
   - Check channel name format (#channel)
   - Test webhook manually

2. Discord not working:
   - Verify webhook URL
   - Test webhook with curl
   - Check server permissions

### Debug Mode

Enable verbose logging in config/config:

```bash
VERBOSE_LOGGING=true
DEBUG_MODE=true
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- IP address providers: ipify.org, ifconfig.me, icanhazip.com
- Alpine Linux team
- Proxmox team

## ✉️ Support

For support:

1. Check the troubleshooting section
2. Review closed issues on GitHub
3. Open a new issue with:
   - Alpine Linux version
   - Script version (git commit hash)
   - Relevant log entries
   - Steps to reproduce the issue
