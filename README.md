# Public IP Tracker

A lightweight, efficient public IP address monitoring system designed for Alpine Linux and LXC containers. This tool tracks changes in your public IP address and sends email notifications when changes are detected.

## Features

- Monitors public IP address changes
- Email notifications for IP changes
- Multiple IP providers fallback system
- Efficient logging with rotation
- Health monitoring
- Designed for Alpine Linux and LXC containers
- Minimal resource usage
- Configurable check intervals

## Requirements

- Alpine Linux
- curl
- msmtp (for email notifications)
- Basic system utilities (provided by BusyBox)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/public-ip-tracker.git
cd public-ip-tracker
```

2. Run the installation script:
```bash
chmod +x install.sh
./install.sh
```

3. Configure email settings:
```bash
vi /etc/msmtprc
```

4. Edit the configuration file:
```bash
vi /root/public-ip-tracker/config/config
```

## Configuration

### Main Configuration (config/config)

```bash
# Timezone
TZ=Australia/Sydney

# IP Providers (space-separated list)
IP_PROVIDERS="https://api.ipify.org https://ifconfig.me/ip https://icanhazip.com"

# Email recipient
EMAIL_RECIPIENT="your.email@example.com"

# Logging settings
VERBOSE_LOGGING=false
```

### Email Configuration (/etc/msmtprc)

```
# Gmail example configuration
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

## Usage

The script runs automatically every 5 minutes via cron. You can also run it manually:

```bash
/root/public-ip-tracker/src/ip-tracker.sh
```

## Logs

Logs are stored in:
```
/root/public-ip-tracker/var/log/ip-tracker.log
```

## Testing

Run the test suite:
```bash
cd /root/public-ip-tracker/src/tests
./run-tests.sh
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- IP address providers: ipify.org, ifconfig.me, icanhazip.com
- Alpine Linux team
- Proxmox team

## Support

For support, please open an issue on the GitHub repository.