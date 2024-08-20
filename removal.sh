#!/bin/bash

PUTHERE=$(whoami)

echo "Removing port_changer service and related files..."

# Stop the service if it's running
sudo systemctl stop port_changer.service

# Disable the service
sudo systemctl disable port_changer.service

# Remove the symlink
sudo rm /etc/systemd/system/port_changer.service

# Remove the actual service file and script
rm -rf /home/$PUTHERE/PortSync_Config /home/$PUTHERE/systemd_services

# Reload systemd to reflect the changes
sudo systemctl daemon-reload

# Check to ensure the service has been removed
if systemctl list-units --full -all | grep -q "port_changer.service"; then
    echo "Failed to remove port_changer.service"
else
    echo "Successfully removed port_changer.service"
fi

echo "Cleanup complete."
