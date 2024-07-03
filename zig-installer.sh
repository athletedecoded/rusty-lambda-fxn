#!/bin/bash

INSTALL_DIR="$HOME/zig"
ARCH="$(uname -m)"

# Check for required tools
if ! command -v jq &> /dev/null; then
    echo "jq is required but not installed. Installing jq."
    sudo apt-get install jq
fi

if ! command -v wget &> /dev/null; then
    echo "wget is required but not installed. Installing wget."
    sudo apt-get install wget
fi

# Fetch Zig index
ZIG_INDEX=$(curl -s https://ziglang.org/download/index.json)
LATEST_VERSION=$(echo "$ZIG_INDEX" | jq '.master.version' | tr -d '"')
INSTALLED_VERSION=$(zig version 2>/dev/null)

# If Zig is installed and up to date, exit
if [ $? -eq 0 ] && [ "$INSTALLED_VERSION" == "$LATEST_VERSION" ]; then
    echo "Zig is already updated to the latest version: ${LATEST_VERSION}"
    exit 0
else
    # If not installed or not latest, proceed with update
    TARBALL=$(echo "$ZIG_INDEX" | jq -r ".master.\"$ARCH-linux\".tarball")
    EXPECTED_SIG=$(echo "$ZIG_INDEX" | jq -r ".master.\"$ARCH-linux\".shasum")

    # Move to directory
    cd "$(dirname "$INSTALL_DIR")"

    # Clear old artifacts
    [ -f zig-latest.tar.xz ] && rm zig-latest.tar.xz
    [ -d "$(basename "$INSTALL_DIR")" ] && rm -rf "$(basename "$INSTALL_DIR")"

    # Download tarball
    wget "$TARBALL" -O "zig-latest.tar.xz"

    # Validate tarball
    TARBALL_SIG=$(sha256sum zig-latest.tar.xz | awk '{print $1}')
    if [ "$EXPECTED_SIG" != "$TARBALL_SIG" ]; then
        echo "Checksum failed."
        exit 1
    fi

    # Extract files
    tar xf "zig-latest.tar.xz"
    mv "zig-linux-$ARCH-$LATEST_VERSION" "$(basename "$INSTALL_DIR")"

    # Clean up artifacts
    [ -f zig-latest.tar.xz ] && rm zig-latest.tar.xz

    # Add to PATH
    echo 'export PATH="$PATH:'"$INSTALL_DIR"'"' >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
    echo "Zig has been installed/updated to version $LATEST_VERSION"
fi
