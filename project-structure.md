public-ip-tracker/
├── .gitignore              # Git ignore file
├── README.md              # Project documentation
├── install.sh            # Installation script
├── config/
│   ├── config.default    # Default configuration
│   └── msmtp.default     # Default msmtp configuration
├── src/
│   ├── ip-tracker.sh     # Main script
│   ├── lib/
│   │   ├── config.sh     # Configuration management
│   │   ├── email.sh      # Email functionality
│   │   ├── ip.sh         # IP checking functionality
│   │   ├── log.sh        # Logging functionality
│   │   └── health.sh     # Health check functionality
│   └── tests/            # Test scripts
└── var/                  # Runtime data (ignored by git)
    ├── log/              # Log files
    └── data/             # Application data