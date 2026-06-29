#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- CONFIGURATION ---
SSID="Your_WiFi_Name"
PASSPHRASE="Your_WiFi_Password"
# ---------------------

echo "Detecting Wi-Fi device..."
# Get the first available wireless station name (e.g., wlan0)
DEVICE=$(iwctl device list | awk '/station/ {print $2}' | head -n 1)

if [ -z "$DEVICE" ]; then
    echo "Error: No Wi-Fi device found in station mode." >&2
    exit 1
fi

echo "Using device: $DEVICE"

echo "Powering on device and adapter..."
iwctl device "$DEVICE" set-property Powered on
# Ensure the parent adapter is also powered on
ADAPTER=$(iwctl device "$DEVICE" show | awk '/Adapter/ {print $2}')
if [ -n "$ADAPTER" ]; then
    iwctl adapter "$ADAPTER" set-property Powered on
fi

echo "Scanning for networks..."
iwctl station "$DEVICE" scan
# Give the hardware a brief window to complete the broadcast scan
sleep 2

echo "Connecting to SSID: $SSID..."
iwctl --passphrase="$PASSPHRASE" station "$DEVICE" connect "$SSID"

echo "Successfully triggered connection via iwd."
