#!/bin/bash
exec > /tmp/port_changer.log 2>&1
echo "Starting script..."

# Prompt for sudo password upfront
sudo -v

# Wait for PIA client process to launch
while ! pgrep -x "pia-client" > /dev/null; do
  echo "Waiting for PIA client..."
  sleep 1
done

echo "PIA client detected."

# Wait for the wgpia0 interface to connect
while ! ip link show wgpia0 > /dev/null 2>&1; do
  echo "Waiting for wgpia0 interface..."
  sleep 1
done

echo "Interface wgpia0 is up."

sleep 3

# Wait for the wgpia0 interface to connect
while ! ip link show wgpia0 > /dev/null 2>&1; do
  echo "Waiting for wgpia0 interface..."
  sleep 1
done

# Loop until the public IP is correctly retrieved
while true; do
  pubip=$(piactl get pubip)
  if [[ "$pubip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Public IP: $pubip"
    break
  else
    echo "Public IP not detected, retrying..."
    sleep 3

    # Close the PIA GUI
    killall pia-client

    # Wait a moment before reopening
    sleep 3

    # Reopen the PIA GUI with the correct environment settings and command
    while ! pgrep -x "pia-client" > /dev/null; do
      nohup env XDG_SESSION_TYPE=X11 /opt/piavpn/bin/pia-client %u &
      echo "Trying to reopen PIA client..."
      sleep 1
    done

    echo "PIA client reopened and detected."

    # Wait for the wgpia0 interface to connect
    while ! ip link show wgpia0 > /dev/null 2>&1; do
      echo "Waiting for wgpia0 interface..."
      sleep 1
    done

    echo "Interface wgpia0 is up."

    sleep 5

    # Wait for PIA client process to launch
    while ! pgrep -x "pia-client" > /dev/null; do
      echo "Waiting for PIA client..."
      sleep 1
    done

    echo "PIA client detected."

    # Wait for the wgpia0 interface to connect
    while ! ip link show wgpia0 > /dev/null 2>&1; do
      echo "Waiting for wgpia0 interface..."
      sleep 1
    done
  fi
done

# Retrieve the forwarded port using piactl
port=$(sudo piactl get portforward)
echo "Retrieved port: $port"

# Update qBittorrent configuration file
config_file="/home/$USER/.config/qBittorrent/qBittorrent.conf"
sudo sed -i "s/Session\\\\Port=.*/Session\\\\Port=$port/" $config_file
echo "Configuration file updated."

# Define the path for old ports
old_port_path="/home/$USER/PortSync_Config"
mkdir -p "$old_port_path"
old_port_file="$old_port_path/old.port.check.txt"

# Check if old.port.check.txt exists
if [ -f "$old_port_file" ]; then
  echo "File old.port.check.txt exists."
else
  # If the file does not exist, create it with the current port
  echo $port > "$old_port_file"
  echo "Created old.port.check.txt with port: $port"
fi

# Read the file and compare the port
old_port=$(head -n 1 "$old_port_file")
if [ "$old_port" == "$port" ]; then
  echo "Port is the same, no action needed."
else
  # If the port is different, update the file
  echo "Port is different. Updating old.port.check.txt."
  old_port=$(head -n 1 "$old_port_file")
  echo -e "$port\nold.$old_port" > "$old_port_file"
  echo "Updated old.port.check.txt with new port: $port"
fi

# Check if the port is already allowed in UFW
if sudo ufw status | grep -q "$port"; then
  echo "Port $port is already allowed by UFW. No action needed."
else
  echo "Port $port is not allowed by UFW. Adding port to UFW."
  sudo ufw allow $port
  echo "Port $port has been added to UFW."
fi

# Check if the old port is in UFW and delete it if it is
if sudo ufw status | grep -q "$old_port"; then
  echo "Old port $old_port is in UFW. Deleting old port from UFW."
  sudo ufw delete allow $old_port
  echo "Old port $old_port has been deleted from UFW."
fi
