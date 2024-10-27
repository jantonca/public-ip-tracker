# Public IP Tracker

A lightweight and efficient public IP monitoring system designed for Alpine Linux and LXC containers. This tool tracks changes in your public IP address and sends email notifications when changes are detected.

## 🌟 Features

- 📡 Real-time public IP address monitoring
- 📧 Email notifications for IP changes
- 🔄 Multiple IP providers with fallback system
- 📊 System health monitoring
- 📝 Efficient logging with rotation
- 🛡️ Security-focused configuration
- 🏃‍♂️ Low resource usage
- 🐳 Optimized for Alpine Linux and LXC containers

## 📋 Prerequisites

- Alpine Linux (tested on version 3.x)
- Root access
- Basic system utilities (provided by BusyBox)
- Internet connection

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

## ⚙️ Configuration

### Main Configuration (config/config)

Edit the main configuration file:

```bash
vi config/config
```

Essential settings to modify:

```bash
# Email recipient for notifications
EMAIL_RECIPIENT="your-email@domain.com"

# Timezone
TZ="Your/Timezone"

# Optional: Adjust check intervals and thresholds
DISK_THRESHOLD=90
MEMORY_THRESHOLD=90
LOAD_THRESHOLD=4
```

### Email Configuration (/etc/msmtprc)

Edit the email configuration:

```bash
vi /etc/msmtprc
```

For Gmail (recommended setup):

```
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

### Cloudflare Integration

To enable Cloudflare DNS updates:

1. Set `CLOUDFLARE_ENABLED=true` in your config file
2. Configure your Cloudflare credentials:

```bash
# Cloudflare authentication
CLOUDFLARE_AUTH_EMAIL="your-email@domain.com"
CLOUDFLARE_AUTH_METHOD="token"    # Use "token" for API Token or "global" for Global API Key
CLOUDFLARE_AUTH_KEY="your-api-key-or-token"
CLOUDFLARE_ZONE_ID="your-zone-id"
CLOUDFLARE_RECORD_NAME="your.domain.com"

# DNS settings
CLOUDFLARE_TTL=3600
CLOUDFLARE_PROXY=false
CLOUDFLARE_SITE_NAME="Your Site Name"
```

Optional: Configure notifications via Slack or Discord:

```bash
# Slack notification
CLOUDFLARE_SLACK_CHANNEL="#your-channel"
CLOUDFLARE_SLACK_URI="https://hooks.slack.com/services/your-webhook-uri"

# Discord notification
CLOUDFLARE_DISCORD_URI="https://discord.com/api/webhooks/your-webhook-uri"
```

To find your Cloudflare credentials:

1. Zone ID: Dashboard → Domain → Overview → Zone ID
2. API Token: Dashboard → Profile → API Tokens → Create Token
3. Global API Key: Dashboard → Profile → API Tokens → View Global API Key

#### Testing Cloudflare Integration

Test your Cloudflare configuration:

```bash
# Force an update check
/root/public-ip-tracker/src/ip-tracker.sh
```

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
