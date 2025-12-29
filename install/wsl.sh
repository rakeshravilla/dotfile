sudo apt update
xargs sudo apt install -y < packages/apt.txt

# Ensure zsh
if ! command -v zsh >/dev/null; then
  sudo apt install -y zsh
fi

# Set default shell
if [[ "$SHELL" != *zsh ]]; then
  chsh -s "$(which zsh)"
fi

# Windows WezTerm Link
if command -v cmd.exe >/dev/null; then
    echo "WSL detected. Setting up Windows WezTerm link..."
    
    # Get dotfiles root
    INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    DOTFILES_ROOT="$(dirname "$INSTALL_DIR")"
    WEZTERM_CONFIG="$DOTFILES_ROOT/wezterm/wezterm.lua"
    
    # Resolve Windows paths
    WIN_CONFIG_PATH=$(wslpath -w "$WEZTERM_CONFIG")
    WIN_HOME=$(cmd.exe /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r')
    TARGET_LINK="$WIN_HOME\\.wezterm.lua"
    
    echo "Linking $TARGET_LINK -> $WIN_CONFIG_PATH"
    
    # Change to a safe directory to avoid "UNC paths not supported" warning from cmd.exe
    cd /mnt/c
    
    # Clean up existing link/file
    cmd.exe /c "if exist \"$TARGET_LINK\" del \"$TARGET_LINK\"" >/dev/null 2>&1
    
    # Create symlink
    if cmd.exe /c mklink "$TARGET_LINK" "$WIN_CONFIG_PATH"; then
        echo "[OK] Windows link created successfully."
    else
        echo "[WARNING] Failed to create Windows symlink."
        echo "  - Ensure Windows Developer Mode is enabled."
        echo "  - OR run this script (WSL) as Administrator."
    fi
    
    # Return to previous directory (optional but good practice)
    cd - >/dev/null
fi
