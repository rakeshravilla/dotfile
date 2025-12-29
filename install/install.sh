#!/usr/bin/env bash
set -e

# Get the directory where the script is located to correctly source other scripts
# logic: assuming script is run from dotfiles root or install/ dir
# Let's align with user request: ./install/install.sh
# We should probably get the project root.

# If we are in install/, go up one level.
# Or just rely on the user running it from root as per instructions.
# User instructions: cd ~/dotfiles && ./install/install.sh
# So CWD is dotfiles root.

if [[ "$(uname -s)" == "Darwin" ]]; then
  source install/mac.sh
elif grep -qi microsoft /proc/version; then
  source install/wsl.sh
else
  echo "Unsupported OS"
  exit 1
fi

source install/common.sh
source scripts/link.sh
