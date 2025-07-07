#!/bin/bash
# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# ┌─────────────────────────────────────────────────────────┐
# │                Metro AI Suite Installer                 │
# │                                                         │
# │  Interactive installation and setup for Edge AI Suites  │
# └─────────────────────────────────────────────────────────┘

set -e # Exit immediately if a command exits with non-zero status

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
MAGENTA="\033[35m"
GRAY="\033[90m"
BG_BLUE="\033[44m"
UNDERLINE="\033[4m"
RESET="\033[0m"

# Global variables
VERBOSE=false
INSTALL_DIR="$HOME/edge-ai-suites"
SUMMARY_FILE="/tmp/metro_ai_install_summary.txt"
SKIP_HARDWARE_CHECK=false
SKIP_SOFTWARE_CHECK=false

# Advanced log functions with timestamps and formatting
log_info() { 
    echo -e "${BLUE}[INFO]${RESET} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" >> "$SUMMARY_FILE"
}
log_success() { 
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS: $1" >> "$SUMMARY_FILE"
}
log_warning() { 
    echo -e "${YELLOW}[WARNING]${RESET} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$SUMMARY_FILE"
}
log_error() { 
    echo -e "${RED}[ERROR]${RESET} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$SUMMARY_FILE"
}
log_section() { 
    echo -e "\n${BG_BLUE}${BOLD} $1 ${RESET}\n"
    echo -e "\n========== $1 ==========" >> "$SUMMARY_FILE"
}
log_step() {
    echo -e "${MAGENTA}[Step $1]${RESET} $2"
}

# Progress indicator functions
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p $pid > /dev/null; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

show_progress() {
    local message="$1"
    echo -en "${CYAN}${message}${RESET}"
    "$@" &>/dev/null &
    spinner $!
    if [ $? -eq 0 ]; then
        echo -e " ${GREEN}✓${RESET}"
    else
        echo -e " ${RED}✗${RESET}"
        return 1
    fi
}

# Function to check if a command exists and is executable
command_exists() {
    command -v "$1" &> /dev/null
}

# Print a separator line
print_separator() {
    echo -e "${GRAY}─────────────────────────────────────────────────────────${RESET}"
}

# Parse command line arguments
parse_arguments() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --install-dir=*)
                INSTALL_DIR="${1#*=}"
                ;;
            --verbose)
                VERBOSE=true
                ;;
            --skip-hardware-check)
                SKIP_HARDWARE_CHECK=true
                ;;
            --skip-software-check)
                SKIP_SOFTWARE_CHECK=true
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown parameter: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
        shift
    done
}

# Show help information
show_help() {
    echo -e "${BOLD}Metro AI Suite Installer${RESET}"
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --install-dir=DIR       Set installation directory (default: $HOME/edge-ai-suites)"
    echo "  --verbose               Enable verbose output"
    echo "  --skip-hardware-check   Skip hardware compatibility check"
    echo "  --skip-software-check   Skip software dependency check"
    echo "  -h, --help              Show this help message and exit"
}

# Show welcome screen
show_welcome() {
    clear
    echo -e "${BOLD}${BLUE}"
    echo "┌─────────────────────────────────────────────────────────┐"
    echo "│                                                         │"
    echo "│               Metro AI Suite Installer                  │"
    echo "│                                                         │"
    echo "│              Intel Edge AI Suite Platform               │"
    echo "│                                                         │"
    echo "└─────────────────────────────────────────────────────────┘"
    echo -e "${RESET}"
    echo -e "This installer will set up the Metro AI Suite components on your system."
    echo -e "It will check your hardware and software compatibility, then download"
    echo -e "and configure the necessary components."
    echo
    echo -e "${YELLOW}Installation directory: ${BOLD}$INSTALL_DIR${RESET}"
    echo
    print_separator
    echo
    
    # Start installation log
    echo "Metro AI Suite Installation Log" > "$SUMMARY_FILE"
    echo "Date: $(date)" >> "$SUMMARY_FILE"
    echo "Installation Directory: $INSTALL_DIR" >> "$SUMMARY_FILE"
    echo >> "$SUMMARY_FILE"
}

# Ask user for confirmation
confirm_action() {
    local message="$1"
    local default="${2:-Y}"
    
    local prompt
    if [ "$default" = "Y" ]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    while true; do
        read -p "$message $prompt " response
        response="${response:-$default}"
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}


# Section 1: Hardware Check
check_hardware() {
    if [ "$SKIP_HARDWARE_CHECK" = true ]; then
        log_info "Hardware check skipped by user request"
        return 0
    fi

    log_section "Hardware Check"
    log_step "1" "Checking system hardware compatibility"
    print_separator

    # Check CPU
    echo -en "${CYAN}Checking CPU...${RESET}"
    cpu_info=$(grep "model name" /proc/cpuinfo | head -n 1 | cut -d ':' -f 2 | sed 's/^ *//' 2>/dev/null || echo "Unknown")
    cpu_cores=$(grep -c processor /proc/cpuinfo 2>/dev/null || echo "Unknown")
    
    if [[ "$cpu_info" == *"Intel"* ]]; then
        echo -e " ${GREEN}✓${RESET} ${BOLD}$cpu_info${RESET} with $cpu_cores cores"
        log_success "Intel CPU detected: $cpu_info with $cpu_cores cores"
    else
        echo -e " ${YELLOW}!${RESET} ${BOLD}$cpu_info${RESET} with $cpu_cores cores"
        log_warning "Non-Intel CPU detected: $cpu_info with $cpu_cores cores"
        log_warning "Some Intel-specific features may not be available"
    fi

    # Check RAM
    echo -en "${CYAN}Checking RAM...${RESET}"
    total_ram=$(free -h 2>/dev/null | grep Mem | awk '{print $2}' || echo "Unknown")
    free_ram=$(free -h 2>/dev/null | grep Mem | awk '{print $4}' || echo "Unknown")
    echo -e " ${GREEN}✓${RESET} ${BOLD}$total_ram${RESET} total, ${BOLD}$free_ram${RESET} free"
    log_info "RAM: $total_ram total, $free_ram free"
    
    # Check for Intel GPU
    echo -en "${CYAN}Checking for Intel GPU...${RESET}"
    if command_exists lspci && lspci | grep -i vga | grep -i intel > /dev/null; then
        intel_gpu=$(lspci | grep -i vga | grep -i intel | cut -d ':' -f 3)
        echo -e " ${GREEN}✓${RESET} ${BOLD}$intel_gpu${RESET}"
        log_success "Intel GPU detected: $intel_gpu"
        
        # Check if Intel GPU drivers are installed
        echo -en "${CYAN}Checking Intel GPU drivers...${RESET}"
        if command_exists intel_gpu_top; then
            echo -e " ${GREEN}✓${RESET} Intel GPU tools installed"
            log_success "Intel GPU tools are installed"
        else
            echo -e " ${YELLOW}!${RESET} Intel GPU tools not found"
            log_warning "Intel GPU detected but intel-gpu-tools not found"
            echo -e "  ${GRAY}→ Consider installing with: sudo apt install intel-gpu-tools${RESET}"
        fi
    else
        echo -e " ${YELLOW}!${RESET} No Intel GPU detected"
        log_warning "No Intel GPU detected"
    fi

    # Check for Intel NPU (Neural Processing Unit)
    echo -en "${CYAN}Checking for Intel NPU...${RESET}"
    npu_detected=false
    
    if [ -d "/dev/intel_ipu" ]; then
        npu_detected=true
    elif command_exists lspci && lspci | grep -i "processing unit" | grep -i intel > /dev/null; then
        npu_detected=true
    fi
    
    if [ "$npu_detected" = true ]; then
        echo -e " ${GREEN}✓${RESET} Intel NPU detected"
        log_success "Intel NPU detected"
    else
        echo -e " ${YELLOW}!${RESET} No Intel NPU detected"
        log_warning "No Intel NPU detected"
    fi

    # Check for acceleration capabilities 
    log_info "Checking for acceleration capabilities..."
    
    # Check for OpenVINO
    if command -v openvino_c_api --version &> /dev/null; then
        openvino_version=$(openvino_c_api --version 2>&1 | grep -oP '(?<=OpenVINO Runtime Version: )[0-9.]+')
        log_success "OpenVINO Runtime detected: version $openvino_version"
    else
        log_info "OpenVINO Runtime not detected"
    fi

}

# Section 2: Software Check
check_software() {
    if [ "$SKIP_SOFTWARE_CHECK" = true ]; then
        log_info "Software dependency check skipped by user request"
        return 0
    fi

    log_section "Software Dependencies Check"
    log_step "2" "Verifying required software dependencies"
    print_separator

    # Check OS
    echo -en "${CYAN}Checking operating system...${RESET}"
    if [ -f /etc/os-release ]; then
        os_name=$(grep -oP '(?<=^NAME=).+' /etc/os-release 2>/dev/null | tr -d '"' || echo "Unknown")
        os_version=$(grep -oP '(?<=^VERSION=).+' /etc/os-release 2>/dev/null | tr -d '"' || echo "")
        echo -e " ${GREEN}✓${RESET} ${BOLD}$os_name $os_version${RESET}"
        log_success "OS: $os_name $os_version"
    else
        os_name=$(uname -s)
        echo -e " ${GREEN}✓${RESET} ${BOLD}$os_name${RESET}"
        log_success "OS: $os_name"
    fi

    # Check kernel version
    echo -en "${CYAN}Checking kernel version...${RESET}"
    kernel=$(uname -r)
    echo -e " ${GREEN}✓${RESET} ${BOLD}$kernel${RESET}"
    log_info "Kernel version: $kernel"

    # Check Python version
    echo -en "${CYAN}Checking Python...${RESET}"
    if command_exists python3; then
        python_version=$(python3 --version 2>&1)
        echo -e " ${GREEN}✓${RESET} ${BOLD}$python_version${RESET}"
        log_success "$python_version"
        
        # Check pip
        echo -en "${CYAN}Checking pip...${RESET}"
        if command_exists pip3; then
            pip_version=$(pip3 --version | cut -d ' ' -f 1-2)
            echo -e " ${GREEN}✓${RESET} ${BOLD}$pip_version${RESET}"
            log_success "pip: $pip_version"
        else
            echo -e " ${RED}✗${RESET} pip3 is not installed"
            log_warning "pip3 is not installed"
            echo -e "  ${GRAY}→ Consider installing with: sudo apt install python3-pip${RESET}"
        fi
    else
        echo -e " ${RED}✗${RESET} Python 3 is not installed"
        log_error "Python 3 is not installed"
        echo -e "  ${GRAY}→ Install with: sudo apt install python3 python3-pip${RESET}"
    fi

    # Check Docker version
    log_info "Checking Docker..."
    if command -v docker &> /dev/null; then
        docker_version=$(docker --version | cut -d ' ' -f 3 | tr -d ',')
        log_success "Docker: $docker_version"
        
        # Check Docker Compose
        if command -v docker-compose &> /dev/null; then
            compose_version=$(docker-compose --version | cut -d ' ' -f 3 | tr -d ',')
            log_success "Docker Compose: $compose_version"
        else
            # Check Docker Compose plugin (newer versions)
            if docker compose version &> /dev/null; then
                compose_version=$(docker compose version | grep "Docker Compose version" | cut -d ' ' -f 4)
                log_success "Docker Compose (plugin): $compose_version"
            else
                log_warning "Docker Compose is not installed"
            fi
        fi
        
        # Check docker daemon running
        if docker info &> /dev/null; then
            echo -e " ${GREEN}✓${RESET} Docker daemon is running"
            log_success "Docker daemon is running"
        else
            echo -e " ${RED}✗${RESET} Docker daemon is not running"
            log_error "Docker daemon is not running"
            echo -e "  ${GRAY}→ Start Docker with: sudo systemctl start docker${RESET}"
            echo -e "  ${GRAY}→ Or add yourself to docker group: sudo usermod -aG docker $USER${RESET}"
        fi
    else
        echo -e " ${RED}✗${RESET} Docker is not installed"
        log_error "Docker is not installed"
        echo -e "  ${GRAY}→ Install Docker with: curl -fsSL https://get.docker.com | sh${RESET}"
    fi

    # Check Git version
    echo -en "${CYAN}Checking Git...${RESET}"
    if command_exists git; then
        git_version=$(git --version | cut -d ' ' -f 3)
        echo -e " ${GREEN}✓${RESET} ${BOLD}$git_version${RESET}"
        log_success "Git: $git_version"
    else
        echo -e " ${RED}✗${RESET} Git is not installed"
        log_error "Git is not installed"
        echo -e "  ${GRAY}→ Install Git with: sudo apt-get install git${RESET}"
    fi
    
    print_separator
}

# Section 3: Download Components
download_components() {
    log_section "Component Installation"
    log_step "3" "Downloading and configuring Metro AI Suite components"
    print_separator
    
    # Create installation directory if it doesn't exist
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -en "${CYAN}Creating installation directory...${RESET}"
        mkdir -p "$INSTALL_DIR"
        echo -e " ${GREEN}✓${RESET} Created $INSTALL_DIR"
        log_success "Created installation directory: $INSTALL_DIR"
    fi
    
    # Define repository details
    base_dir="$INSTALL_DIR"
    metro_dir="$base_dir"
    
    # GitHub organization - using public HTTPS URLs (no authentication)
    github_org="https://github.com/open-edge-platform"
    
    echo -e "${BOLD}Installation location:${RESET} $base_dir"
    log_info "Installation directory: $base_dir"
    
    # Component selection
    components="edge-ai-suites"
    
    # Check for existing components
    echo -e "\n${BOLD}Checking for existing components...${RESET}"
    existing_components=0
    total_components=0
    
    for component in $components; do
        total_components=$((total_components+1))
        if [ -d "$base_dir/$component" ]; then
            existing_components=$((existing_components+1))
            echo -e " ${YELLOW}!${RESET} ${BOLD}$component${RESET} already exists"
            log_info "Component directory already exists: $component"
        fi
    done
    
    if [ "$existing_components" -eq "$total_components" ]; then
        log_success "All components already downloaded"
        
        if confirm_action "Would you like to update existing components?" "Y"; then
            echo -e "\n${BOLD}Updating existing components...${RESET}"
        else
            return 0
        fi
    else
        echo -e "\n${BOLD}Downloading components...${RESET}"
    fi
    
    # Clone/update components
    for component in $components; do
        component_dir="$base_dir/$component"
        
        if [ -d "$component_dir" ]; then
            echo -en " ${CYAN}Updating ${BOLD}$component${RESET}${CYAN}...${RESET}"
            cd "$component_dir"
            if git pull &>/dev/null; then
                echo -e " ${GREEN}✓${RESET} Updated"
                log_success "Updated $component successfully"
            else
                echo -e " ${RED}✗${RESET} Failed to update"
                log_error "Failed to update $component"
            fi
        else
            echo -en " ${CYAN}Cloning ${BOLD}$component${RESET}${CYAN}...${RESET}"
            cd "$base_dir"
            # Cloning public repository (no authentication)
            if git clone "$github_org/$component.git" &>/dev/null; then
                echo -e " ${GREEN}✓${RESET} Cloned"
                log_success "Cloned $component successfully"
            else
                echo -e " ${RED}✗${RESET} Failed to clone"
                log_error "Failed to clone $component"
            fi
        fi
    done
    
    # Setup additional requirements if needed
    if [ -d "$base_dir/metro-ai-suite" ] && [ -f "$base_dir/metro-ai-suite/requirements.txt" ]; then
        echo -en "\n${CYAN}Setting up Python dependencies...${RESET}"
        cd "$base_dir/metro-ai-suite"
        if command_exists pip3 && pip3 install -r requirements.txt &>/dev/null; then
            echo -e " ${GREEN}✓${RESET} Installed successfully"
            log_success "Installed Python requirements"
        else
            echo -e " ${YELLOW}!${RESET} Could not install requirements automatically"
            log_warning "Could not install requirements automatically"
            echo -e "  ${GRAY}→ Run manually: pip3 install -r $base_dir/metro-ai-suite/requirements.txt${RESET}"
        fi
    fi
    
    print_separator
    
    # Create a simple setup summary
    echo -e "\n${BOLD}${GREEN}Installation Summary:${RESET}"
    echo -e " ${GREEN}•${RESET} Installation directory: ${BOLD}$base_dir${RESET}"
    echo -e " ${GREEN}•${RESET} Components installed: ${BOLD}$components${RESET}"
    echo -e " ${GREEN}•${RESET} Log file: ${BOLD}$SUMMARY_FILE${RESET}"
    
    # Next steps
    echo -e "\n${BOLD}${BLUE}Next Steps:${RESET}"
    echo -e " ${BLUE}1.${RESET} Navigate to individual component directories"
    echo -e " ${BLUE}2.${RESET} Follow README.md instructions for each component"
    echo -e " ${BLUE}3.${RESET} Run docker-compose to start required services"
    
    print_separator
}

# Main execution
main() {
    # Parse command line arguments first
    parse_arguments "$@"
    
    # Show welcome screen
    show_welcome
    
    # Run the installation steps
    check_hardware
    check_software
    download_components
    
    log_section "Installation Complete"
    log_success "Metro AI Suite has been set up successfully."
    echo -e "\n${BOLD}${GREEN}Thank you for installing Metro AI Suite!${RESET}"
    echo -e "${GREEN}You can find a detailed installation log at: ${GRAY}$SUMMARY_FILE${RESET}"
    
    echo -e "\n${BOLD}${BLUE}Thank you for using Metro AI Suite Installer!${RESET}"
}

# Execute main function
main "$@"
