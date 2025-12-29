#!/bin/bash

. scripts/utils.sh
. scripts/prerequisites.sh
. scripts/brew-install-custom.sh
. scripts/osx-defaults.sh
. scripts/symlinks.sh

info "Dotfiles intallation initialized..."

# ------------------------------------------------------------------------------
# OS Detection & Setup
# ------------------------------------------------------------------------------

OS="$(uname -s)"
case "${OS}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    *)          machine="UNKNOWN:${OS}"
esac

info "Detected operating system: $machine"

# ------------------------------------------------------------------------------
# Installation Logic
# ------------------------------------------------------------------------------

read -p "Install apps? [y/n] " install_apps
read -p "Overwrite existing dotfiles? [y/n] " overwrite_dotfiles

if [[ "$install_apps" == "y" ]]; then
    printf "\n"
    info "===================="
    info "Installing Packages"
    info "===================="

    if [[ "$machine" == "Mac" ]]; then
        info "Running macOS installation..."
        
        info "--- Prerequisites ---"
        install_xcode
        install_homebrew

        info "--- Apps (Homebrew) ---"
        install_custom_formulae
        install_custom_casks
        run_brew_bundle
        
    elif [[ "$machine" == "Linux" ]]; then
        info "Running Linux installation..."
        
        # Source the linux install script
        . scripts/linux-install.sh
        
        install_apt_packages
        install_linux_custom
    else
        error "Unsupported operating system: $machine"
    fi
fi

if [[ "$machine" == "Mac" ]]; then
    printf "\n"
    info "===================="
    info "OSX System Defaults"
    info "===================="
    
    register_keyboard_shortcuts
    apply_osx_system_defaults
fi

printf "\n"
info "===================="
info "Terminal"
info "===================="

info "Adding .hushlogin file to suppress 'last login' message in terminal..."
touch ~/.hushlogin

printf "\n"
info "===================="
info "Symbolic Links"
info "===================="

chmod +x ./scripts/symlinks.sh

# Pass the machine type to symlinks script or let it detect it too
# For now, we rely on the existing symlinks script but we will need to update it 
# to handle specific config files.

if [[ "$overwrite_dotfiles" == "y" ]]; then
    warning "Deleting existing dotfiles..."
    ./scripts/symlinks.sh --delete --include-files
fi
./scripts/symlinks.sh --create

success "Dotfiles set up successfully."
