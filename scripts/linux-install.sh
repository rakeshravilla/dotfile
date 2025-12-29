#!/bin/bash

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

. $SCRIPT_DIR/utils.sh

install_apt_packages() {
    info "Detected Linux (Ubuntu/Debian). Updating apt and installing core packages..."
    
    # Add Neovim PPA for latest version (0.10+) since 0.9.5 is missing features (ge, etc.)
    # Note: Using unstable PPA because stable is lagging for Noble (24.04)
    if ! grep -q "neovim-ppa/unstable" /etc/apt/sources.list.d/* 2>/dev/null; then
        info "Adding Neovim unstable PPA..."
        sudo add-apt-repository -y ppa:neovim-ppa/unstable
    fi

    sudo apt update
    # sudo apt upgrade -y # Optional: might be too aggressive for some users

    # List of packages equivalent to key Brewfile items
    # Core tools
    packages=(
        build-essential
        curl
        git
        zsh
        unzip
        locales
        
        # Tools
        cmake
        fzf
        neofetch
        ranger
        ripgrep
        tmux
        xclip
        zlib1g-dev
        libssl-dev    # openssl equivalent
        libsqlite3-dev # sqlite equivalent
        poppler-utils
        
        # Zsh Plugins (Common on Ubuntu)
        zsh-syntax-highlighting
        zsh-autosuggestions
        
        # Editors & Plugins Support
        neovim
        luarocks
        liblua5.1-0-dev
    )

    info "Installing packages: ${packages[*]}"
    sudo apt install -y "${packages[@]}"
    
    # Fix locale warnings common on minimal Ubuntu images
    if ! grep -q "en_US.UTF-8" /var/lib/locales/supported.d/local 2>/dev/null; then
        info "Generating en_US.UTF-8 locale..."
        sudo locale-gen en_US.UTF-8
        sudo update-locale LANG=en_US.UTF-8
    fi
    
    # AWS CLI (Ubuntu sometimes has issues with just 'awscli', but we try)
    if ! command -v aws &> /dev/null; then
         info "Installing AWS CLI..."
         sudo apt install -y awscli || warning "Failed to install awscli via apt. You may need to install it manually."
    fi
}

install_linux_custom() {
    # Custom installs for things not easily found or outdated in standard apt repos
    
    # Example: Starship
    if ! command -v starship &> /dev/null; then
        info "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
    
    # Ensure local bin is in path for immediate usage if needed
    export PATH="$HOME/.local/bin:$PATH"

    # Example: Zoxide
    if ! command -v zoxide &> /dev/null; then
        info "Installing Zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
    fi
    
    # Pyenv
    if [ ! -d "$HOME/.pyenv" ]; then
         info "Installing Pyenv..."
         curl https://pyenv.run | bash
         
         # Add to shell for remainder of script (though usually needs restart)
         export PYENV_ROOT="$HOME/.pyenv"
         export PATH="$PYENV_ROOT/bin:$PATH"
    fi

    # Poetry
    if ! command -v poetry &> /dev/null; then
        info "Installing Poetry..."
        curl -sSL https://install.python-poetry.org | python3 -
    fi

    # Eza (Better ls)
    if ! command -v eza &> /dev/null; then
        info "Installing Eza..."
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt update
        sudo apt install -y eza
    fi

    # Lazygit
    if ! command -v lazygit &> /dev/null; then
        info "Installing Lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        sudo install lazygit /usr/local/bin
        rm lazygit lazygit.tar.gz
    fi
}
