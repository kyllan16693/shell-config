#!/usr/bin/env bash

BASE_URL="https://10.0.0.24"

# Function to download and source a script
download_and_source_script() {
    local script_name=$1
    local temp_script=$(mktemp)
    curl -s "$BASE_URL/$script_name" -o "$temp_script"
    if [ $? -ne 0 ]; then
        log_error "Failed to download $script_name. Exiting..."
        rm "$temp_script"
        exit 1
    fi
    source "$temp_script"
    if [ $? -ne 0 ]; then
        log_error "Failed to source $script_name. Exiting..."
        rm "$temp_script"
        exit 1
    fi
    rm "$temp_script"
    log_debug "Downloaded and sourced $script_name"
}

# Add util functions if not already defined
if ! declare -f spinner &>/dev/null; then
    download_and_source_script "utils.sh"
fi

# Function to install oh-my-posh
install_oh_my_posh() {
    if command -v oh-my-posh &>/dev/null; then
        log_info "oh-my-posh is already installed."
    else
        curl -s https://ohmyposh.dev/install.sh | bash -s >"$temp_file" 2>&1 &
        spinner $! "Installing oh-my-posh"
    fi
}

# Function to configure oh-my-posh
configure_oh_my_posh() {
    # Create .ohmyposh directory if it doesn't exist
    mkdir -p "$HOME/.ohmyposh"
    
    # Download the config.toml file
    if [ -f "$HOME/.ohmyposh/config.toml" ]; then
        if ask "oh-my-posh config.toml already exists. Do you want to overwrite it?"; then
            curl -fsSL "$BASE_URL/conf/config.toml" -o "$HOME/.ohmyposh/config.toml" >"$temp_file" 2>&1 &
            spinner $! "Downloading oh-my-posh config.toml"
        fi
    else
        curl -fsSL "$BASE_URL/conf/config.toml" -o "$HOME/.ohmyposh/config.toml" >"$temp_file" 2>&1 &
        spinner $! "Downloading oh-my-posh config.toml"
    fi
    
    # Download the .zshrc file
    if [ -f "$HOME/.zshrc" ]; then
        if ask ".zshrc already exists. Do you want to back it up and overwrite it?"; then
            cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
            log_info "Backup created at $HOME/.zshrc.bak"
            curl -fsSL "$BASE_URL/conf/.zshrc" -o "$HOME/.zshrc" >"$temp_file" 2>&1 &
            spinner $! "Downloading .zshrc"
        fi
    else
        curl -fsSL "$BASE_URL/conf/.zshrc" -o "$HOME/.zshrc" >"$temp_file" 2>&1 &
        spinner $! "Downloading .zshrc"
    fi
    
    log_info "oh-my-posh configuration completed."
}

# Function to install zsh
install_zsh() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! brew list zsh &>/dev/null; then
            brew install zsh >"$temp_file" 2>&1 &
            spinner $! "Installing zsh (brew)"
        else
            log_info "zsh is already installed."
        fi
    elif command -v apt-get &>/dev/null; then
        sudo apt install -y zsh >"$temp_file" 2>&1 &
        spinner $! "Installing zsh (apt)"
    elif command -v yum &>/dev/null; then
        sudo yum install -y zsh >"$temp_file" 2>&1 &
        spinner $! "Installing zsh (yum)"
    elif command -v apk &>/dev/null; then
        sudo apk add zsh >"$temp_file" 2>&1 &
        spinner $! "Installing zsh (apk)"
    elif command -v nix-env &>/dev/null; then
        nix-env -iA nixpkgs.zsh >"$temp_file" 2>&1 &
        spinner $! "Installing zsh (nix)"
    else
        log_error "No supported package manager found. Exiting..."
        exit 1
    fi
}

install_shell_tools() {
    current_shell=$(basename "$SHELL")
    log_debug "Current shell: $current_shell"
    
    # If the current shell is bash, ask if the user wants to switch to zsh
    if [[ "$current_shell" == "bash" ]]; then
        if ask "Do you want to switch to zsh?"; then
            # Change the default shell to zsh
            install_zsh
            print_message "Please enter your password to change the default shell to zsh."
            chsh -s $(which zsh)
            current_shell="zsh"
        fi
    fi

    if [[ "$current_shell" == "zsh" ]]; then
        install_oh_my_posh
        configure_oh_my_posh
        log_info "Shell tools installation completed. Please restart your terminal or run 'source ~/.zshrc' to apply changes."
    else
        log_error "Unsupported shell: $current_shell. This script is designed for zsh. Exiting..."
        exit 1
    fi
}

# Check if script is being executed or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    temp_file=$(mktemp)
    install_shell_tools
fi