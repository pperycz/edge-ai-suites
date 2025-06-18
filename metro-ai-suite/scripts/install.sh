#!/bin/bash
# SPDX-FileCopyrightText: (C) 2025 Intel Corporation
# SPDX-License-Identifier: Apache-2.0

# Metro AI Suite Installation Script
# This script:
# 1. Checks hardware (CPU, Intel GPU, NPU)
# 2. Verifies software components and versions (OS, Kernel, Python, Docker)
# 3. Downloads required components using git clone

set -e # Exit immediately if a command exits with non-zero status

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Log functions
log_info() { echo -e "${BLUE}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }
log_section() { echo -e "\n${BOLD}$1${RESET}\n"; }

# Function to check if a command exists and is executable
command_exists() {
    command -v "$1" &> /dev/null
}

# Section 1: Hardware Check
check_hardware() {
    log_section "Hardware Check"

    # Check CPU
    log_info "Checking CPU..."
    cpu_info=$(grep "model name" /proc/cpuinfo | head -n 1 | cut -d ':' -f 2 | sed 's/^ *//')
    cpu_cores=$(grep -c processor /proc/cpuinfo)
    
    if [[ "$cpu_info" == *"Intel"* ]]; then
        log_success "Intel CPU detected: $cpu_info with $cpu_cores cores"
    else
        log_info "CPU: $cpu_info with $cpu_cores cores"
    fi

    # Check RAM
    total_ram=$(free -h | grep Mem | awk '{print $2}')
    log_info "RAM: $total_ram total"

    # Check Intel GPU
    log_info "Checking for Intel GPU..."
    if lspci | grep -i vga | grep -i intel > /dev/null; then
        intel_gpu=$(lspci | grep -i vga | grep -i intel | cut -d ':' -f 3)
        log_success "Intel GPU detected: $intel_gpu"
        
        # Check if Intel GPU drivers are installed
        if command -v intel_gpu_top &> /dev/null; then
            log_success "Intel GPU tools are installed"
        else
            log_warning "Intel GPU detected but intel-gpu-tools may not be installed"
        fi
    else
        log_warning "No Intel GPU detected"
    fi

    # Check for Intel NPU (Neural Processing Unit)
    log_info "Checking for Intel NPU..."
    if [ -d "/dev/intel_ipu" ] || lspci | grep -i "processing unit" | grep -i intel > /dev/null; then
        log_success "Intel NPU detected"
    else
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
    log_section "Software Check"

    # Check OS
    log_info "Checking operating system..."
    if [ -f /etc/os-release ]; then
        os_name=$(grep -oP '(?<=^NAME=).+' /etc/os-release | tr -d '"')
        os_version=$(grep -oP '(?<=^VERSION=).+' /etc/os-release | tr -d '"')
        log_success "OS: $os_name $os_version"
    else
        os_name=$(uname -s)
        log_success "OS: $os_name"
    fi

    # Check kernel version
    kernel=$(uname -r)
    log_info "Kernel version: $kernel"

    # Check Python version
    log_info "Checking Python..."
    if command -v python3 &> /dev/null; then
        python_version=$(python3 --version 2>&1)
        log_success "$python_version"
        
        # Check pip
        if command -v pip3 &> /dev/null; then
            pip_version=$(pip3 --version | cut -d ' ' -f 1-2)
            log_success "pip: $pip_version"
        else
            log_warning "pip3 is not installed"
        fi
    else
        log_error "Python 3 is not installed"
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
        if systemctl is-active --quiet docker; then
            log_success "Docker daemon is running"
        else
            log_error "Docker daemon is not running"
            log_info "Start Docker with: sudo systemctl start docker"
        fi
    else
        log_error "Docker is not installed"
    fi

    # Check Git version
    log_info "Checking Git..."
    if command -v git &> /dev/null; then
        git_version=$(git --version | cut -d ' ' -f 3)
        log_success "Git: $git_version"
    else
        log_error "Git is not installed"
        log_info "Install Git with: sudo apt-get install git"
        exit 1
    fi
}

# Section 3: Download Components
download_components() {
    log_section "Downloading Metro AI Suite Components"
    
    # Define repository details
    base_dir="$HOME"
    metro_dir="$base_dir"
    components=(
        "edge-ai-suites"
    )
    
    # GitHub organization - using public HTTPS URLs (no authentication)
    github_org="https://github.com/open-edge-platform"
    
    log_info "Base directory: $base_dir"
    
    # Check for existing components
    existing_components=0
    for component in "${components[@]}"; do
        if [ -d "$base_dir/$component" ]; then
            existing_components=$((existing_components+1))
            log_info "Component directory already exists: $component"
        fi
    done
    
    if [ "$existing_components" -eq "${#components[@]}" ]; then
        log_success "All components already downloaded"
        return 0
    fi
    
    # Clone/update components
    for component in "${components[@]}"; do
        component_dir="$base_dir/$component"
        
        if [ -d "$component_dir" ]; then
            log_info "Updating existing component: $component"
            cd "$component_dir"
            git pull
            if [ $? -eq 0 ]; then
                log_success "Updated $component successfully"
            else
                log_error "Failed to update $component"
            fi
        else
            log_info "Cloning new component: $component"
            cd "$base_dir"
            # Cloning public repository (no authentication)
            git clone "$github_org/$component.git"
            if [ $? -eq 0 ]; then
                log_success "Cloned $component successfully"
            else
                log_error "Failed to clone $component"
            fi
        fi
    done
    
}

# Main execution
main() {
    clear
    echo -e "${BOLD}==============================================${RESET}"
    echo -e "${BOLD}     Metro AI Suite Installation Script      ${RESET}"
    echo -e "${BOLD}==============================================${RESET}"
    
    check_hardware
    check_software
    download_components
    
    log_section "Installation Complete"
    log_success "Metro AI Suite has been set up successfully."
    log_info "To get started, navigate to individual components and follow their README instructions."
    
    echo -e "${BOLD}==============================================${RESET}"
}

# Execute main function
main
