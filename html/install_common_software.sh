#!/usr/bin/env bash

COMMON_SOFTWARE="git curl wget htop fzf tree unzip zip ripgrep tmux lazygit"

BASE_URL="https://sh.kyllan.dev"

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

# Function to install eza
install_eza() {
    if command -v eza &>/dev/null; then
        log_info "eza is already installed."
        return 0
    fi
    
    if command -v apt-get &>/dev/null; then
        # Install gpg if not available
        if ! command -v gpg &>/dev/null; then
            sudo apt install -y gpg >"$temp_file" 2>&1 &
            spinner $! "Installing gpg"
        fi
        
        # Add eza repository
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg >"$temp_file" 2>&1 &
        spinner $! "Adding eza GPG key"
        
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list >"$temp_file" 2>&1 &
        spinner $! "Adding eza repository"
        
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        
        sudo apt update >"$temp_file" 2>&1 &
        spinner $! "Updating package list"
        
        sudo apt install -y eza >"$temp_file" 2>&1 &
        spinner $! "Installing eza (apt)"
    elif command -v yum &>/dev/null; then
        sudo yum install -y eza >"$temp_file" 2>&1 &
        spinner $! "Installing eza (yum)"
    elif command -v apk &>/dev/null; then
        sudo apk add eza >"$temp_file" 2>&1 &
        spinner $! "Installing eza (apk)"
    elif command -v nix-env &>/dev/null; then
        nix-env -i eza >"$temp_file" 2>&1 &
        spinner $! "Installing eza (nix)"
    elif command -v brew &>/dev/null; then
        brew install eza >"$temp_file" 2>&1 &
        spinner $! "Installing eza (brew)"
    else
        log_warn "eza installation not supported for this package manager."
    fi
}

# Function to install zoxide
install_zoxide() {
    if command -v zoxide &>/dev/null; then
        log_info "zoxide is already installed."
        return 0
    fi
    
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh >"$temp_file" 2>&1 &
    spinner $! "Installing zoxide"
}

# Function to install common software
install_software() {
    if command -v apt-get &>/dev/null; then
        sudo apt update >"$temp_file" 2>&1 &
        spinner $! "Updating package list"
        sudo apt install -y $COMMON_SOFTWARE >"$temp_file" 2>&1 &
        spinner $! "Installing common software (apt)"
    elif command -v yum &>/dev/null; then
        sudo yum install -y $COMMON_SOFTWARE >"$temp_file" 2>&1 &
        spinner $! "Installing common software (yum)"
    elif command -v apk &>/dev/null; then
        sudo apk add $COMMON_SOFTWARE >"$temp_file" 2>&1 &
        spinner $! "Installing common software (apk)"
    elif command -v nix-env &>/dev/null; then
        nix-env -iA nixpkgs.${COMMON_SOFTWARE// / nixpkgs.} >"$temp_file" 2>&1 &
        spinner $! "Installing common software (nix)"
    elif command -v brew &>/dev/null; then
        brew install $COMMON_SOFTWARE >"$temp_file" 2>&1 &
        spinner $! "Installing common software (brew)"
    else
        log_error "No supported package manager found. Exiting..."
        exit 1
    fi
    
    # Install eza separately
    install_eza
    
    # Install zoxide separately
    install_zoxide
}

# Check if the script is being executed or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    temp_file=$(mktemp)
    install_software
fi
