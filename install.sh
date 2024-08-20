#!/bin/bash

PUTHERE=$(whoami)

# Create necessary directories
mkdir -p /home/$PUTHERE/PortSync_Config /home/$PUTHERE/systemd_services

# Write the port_changer.sh script
echo '#!/bin/bash
(exec content of the port_changer.sh script as provided above)
' > /home/$PUTHERE/PortSync_Config/port_changer.sh

# Make the script executable
chmod +x /home/$PUTHERE/PortSync_Config/port_changer.sh

# Write the port_changer.service file
echo '[Unit]
Description=Change Port for qBittorrent upon startup
After=network.target

[Service]
Type=simple
ExecStart=/home/$PUTHERE/PortSync_Config/port_changer.sh
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
' > /home/$PUTHERE/systemd_services/port_changer.service

# Move the service file to /etc/systemd/system and create symlink
sudo ln -s /home/$PUTHERE/systemd_services/port_changer.service /etc/systemd/system/port_changer.service

# Reload systemd, start and enable the service
sudo systemctl daemon-reload
sudo systemctl start port_changer.service
sudo systemctl enable port_changer.service


# Display the output log
cat /tmp/port_changer.log
