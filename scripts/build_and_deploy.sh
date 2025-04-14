#!/bin/bash

set -e

REMOTE_USER="seaward"
DEPLOY_DIR="/opt/ccom_radar_ws"

if [ -z "$1" ]; then
    echo "Usage: $0 <remote_host>"
    exit 1
fi
REMOTE_HOST="$1"

read -s -p "Enter sudo password for $REMOTE_USER@$REMOTE_HOST: " SSHPASS
echo

SCRIPT_DIR="$(realpath $(dirname "${BASH_SOURCE[0]}"))"
WORKSPACE_DIR="$(realpath "$SCRIPT_DIR/..")"
BUILD_TAG=$(cd "$WORKSPACE_DIR" && git describe --tags --abbrev=0 2>/dev/null || echo "build_latest")

BUILD_DIR="$WORKSPACE_DIR/_deploy_build"
INSTALL_DIR="$WORKSPACE_DIR/_deploy_install"

echo ">>> Building workspace with tag: $BUILD_TAG"
rm -rf "$BUILD_DIR" "$INSTALL_DIR"
colcon build \
    --merge-install \
    --base-paths "$WORKSPACE_DIR" \
    --build-base "$BUILD_DIR" \
    --install-base "$INSTALL_DIR"
    

echo ">>> Rsyncing to $REMOTE_HOST..."
rsync -avzP --delete "$INSTALL_DIR/" "$REMOTE_USER@$REMOTE_HOST:/tmp/ccom_radar_ws_install"

echo ">>> Installing to /opt on $REMOTE_HOST..."
ssh "$REMOTE_USER@$REMOTE_HOST" "echo '$SSHPASS' | sudo -S bash -c 'mkdir -p $DEPLOY_DIR && rm -rf $DEPLOY_DIR/* && cp -r /tmp/ccom_radar_ws_install/* $DEPLOY_DIR && chown -R root:root $DEPLOY_DIR'"

echo ">>> ✅ Deployment complete"

