#!/bin/bash
# Create systemd service
echo "Creating systemd service"
sudo tee /etc/systemd/system/srv-02.service > /dev/null <<EOL
[Unit]
Description=Dotnet S3 info service

[Service]
ExecStart=/usr/bin/dotnet /home/ubuntu/srv-02/Automate_HTTP_Service_Deployment/bin/Release/netcoreapp6/linux-x64/publish/srv02.dll
SyslogIdentifier=srv-02
Environment=DOTNET_CLI_HOME=/home/ubuntu

[Install]
WantedBy=multi-user.target
EOL

# Start and enable the service
systemctl daemon-reload
systemctl enable srv-02