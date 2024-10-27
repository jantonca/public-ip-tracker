public-ip-tracker/
├── .gitignore # Git ignore file
├── LICENSE # License file
├── README.md # Documentation
├── install.sh # Installation script
├── config/
│ ├── config.default # Default configuration template
│ └── msmtp.default # Default msmtp configuration template
└── src/
├── ip-tracker.sh # Main script
└── lib/
├── config.sh # Configuration management
├── email.sh # Email functionality
├── ip.sh # IP checking functionality
├── log.sh # Logging functionality
└── health.sh # Health check functionality

# Directories created during installation (not in git):

# /var/

# ├── log/ # Log files

# └── data/ # Runtime data
