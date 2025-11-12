#!/bin/bash

# Fix flutter_bluetooth_serial plugin namespace issue
# This script adds the missing namespace to the plugin's build.gradle

PLUGIN_PATH="$HOME/.pub-cache/hosted/pub.dev/flutter_bluetooth_serial-0.4.0/android/build.gradle"

if [ ! -f "$PLUGIN_PATH" ]; then
    echo "Error: Plugin build.gradle not found at: $PLUGIN_PATH"
    exit 1
fi

echo "Backing up original build.gradle..."
cp "$PLUGIN_PATH" "${PLUGIN_PATH}.backup"

echo "Adding namespace to build.gradle..."

# Check if namespace already exists
if grep -q "namespace" "$PLUGIN_PATH"; then
    echo "Namespace already exists in build.gradle"
    exit 0
fi

# Add namespace after "android {" line
sed -i '' '/android {/a\
    namespace = "io.github.edufolly.flutterbluetoothserial"
' "$PLUGIN_PATH"

echo "Done! Namespace added successfully."
echo "Backup saved at: ${PLUGIN_PATH}.backup"
