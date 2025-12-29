#!/bin/bash


# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

# Get the absolute path of the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/.."

# Determine which config files to use based on OS
OS="$(uname -s)"
CONFIG_FILES=("$DOTFILES_DIR/symlinks.common")

case "${OS}" in
    Linux*)     
        CONFIG_FILES+=("$DOTFILES_DIR/symlinks.linux") 
        ;;
    Darwin*)    
        CONFIG_FILES+=("$DOTFILES_DIR/symlinks.macos") 
        ;;
    *)          
        warning "Unknown OS: $OS. Loading only common symlinks."
        ;;
esac

. $SCRIPT_DIR/utils.sh

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

process_config_file() {
    local config_file="$1"
    local action="$2" # "create" or "delete"
    
    if [ ! -f "$config_file" ]; then
        warning "Configuration file not found: $config_file"
        return
    fi
    
    info "Processing $config_file..."
    
    while IFS=: read -r source target || [ -n "$source" ]; do
        # Skip empty lines, comments, or malformed lines
        [[ -z "$source" || "$source" == \#* ]] && continue
        
        # When deleting, valid line might just be targets, but format is source:target
        # If line is just target (weird legacy?), we handle it. But standard format is key.
        
        if [[ "$action" == "delete" ]]; then
             # For delete, we only need target
             if [[ -z "$target" ]]; then continue; fi
             target=$(eval echo "$target")
             
             if [ -L "$target" ] || { [ "$include_files" == true ] && [ -f "$target" ]; }; then
                rm -rf "$target"
                success "Deleted: $target"
            else
                # silent or verbose? existing script warned.
                # warning "Not found: $target"
                :
            fi
            continue
        fi

        # Create Logic
        if [[ -z "$target" ]]; then continue; fi
        
        source=$(eval echo "$source")
        target=$(eval echo "$target")
        
        if [ ! -e "$source" ]; then
            # warning "Source file '$source' not found. Skipping."
             # Make this verbose only if really needed, otherwise it spams for optional files
            continue
        fi
        
        if [ -L "$target" ]; then
            # warning "Symbolic link already exists: $target"
            :
        elif [ -f "$target" ]; then
            warning "File already exists: $target"
        else
            target_dir=$(dirname "$target")
            if [ ! -d "$target_dir" ]; then
                mkdir -p "$target_dir"
                info "Created directory: $target_dir"
            fi
            ln -s "$source" "$target"
            success "Created symbolic link: $target"
        fi
        
    done <"$config_file"
}

create_symlinks() {
    info "Creating symbolic links..."
    for file in "${CONFIG_FILES[@]}"; do
        process_config_file "$file" "create"
    done
}

delete_symlinks() {
    info "Deleting symbolic links..."
    for file in "${CONFIG_FILES[@]}"; do
        process_config_file "$file" "delete"
    done
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

# Parse arguments
if [ "$(basename "$0")" = "$(basename "${BASH_SOURCE[0]}")" ]; then
    case "$1" in
    "--create")
        create_symlinks
        ;;
    "--delete")
        if [ "$2" == "--include-files" ]; then
            include_files=true
        fi
        delete_symlinks
        ;;
    "--help")
        echo "Usage: $0 [--create | --delete [--include-files] | --help]"
        ;;
    *)
        error "Error: Unknown argument '$1'"
        error "Usage: $0 [--create | --delete [--include-files] | --help]"
        exit 1
        ;;
    esac
fi
