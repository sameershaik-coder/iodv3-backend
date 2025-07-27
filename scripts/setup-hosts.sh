#!/bin/bash

# IOD V3 Backend - Host Management Script
# Manages /etc/hosts entries for local development

set -e

# Configuration
HOSTS_FILE="/etc/hosts"
HOSTS_MARKER="# IOD V3 Backend - Local Development"
HOSTS_ENTRIES=(
    "127.0.0.1 dev.iodv3.local"
    "127.0.0.1 api.iodv3.local"
    "127.0.0.1 accounts.iodv3.local"
    "127.0.0.1 blog.iodv3.local"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if running as root/sudo
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script requires sudo privileges to modify $HOSTS_FILE"
        echo "Please run with: sudo $0 $1"
        exit 1
    fi
}

# Function to backup hosts file
backup_hosts() {
    local backup_file="${HOSTS_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Creating backup: $backup_file"
    cp "$HOSTS_FILE" "$backup_file"
    log_success "Backup created successfully"
}

# Function to check if IOD V3 entries exist
entries_exist() {
    grep -q "$HOSTS_MARKER" "$HOSTS_FILE" 2>/dev/null
}

# Function to add host entries
add_entries() {
    log_info "Adding IOD V3 host entries..."
    
    if entries_exist; then
        log_warning "IOD V3 entries already exist in $HOSTS_FILE"
        log_info "Use 'remove' command first, then 'add' to update entries"
        return 1
    fi
    
    backup_hosts
    
    # Add marker and entries
    echo "" >> "$HOSTS_FILE"
    echo "$HOSTS_MARKER" >> "$HOSTS_FILE"
    
    for entry in "${HOSTS_ENTRIES[@]}"; do
        echo "$entry" >> "$HOSTS_FILE"
        log_info "Added: $entry"
    done
    
    echo "$HOSTS_MARKER" >> "$HOSTS_FILE"
    
    log_success "IOD V3 host entries added successfully"
}

# Function to remove host entries
remove_entries() {
    log_info "Removing IOD V3 host entries..."
    
    if ! entries_exist; then
        log_warning "No IOD V3 entries found in $HOSTS_FILE"
        return 0
    fi
    
    backup_hosts
    
    # Create temporary file without IOD V3 entries
    local temp_file=$(mktemp)
    
    # Copy everything except between the markers
    awk "
        BEGIN { skip = 0 }
        /$HOSTS_MARKER/ { 
            if (skip == 0) { skip = 1; next }
            else { skip = 0; next }
        }
        skip == 0 { print }
    " "$HOSTS_FILE" > "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$HOSTS_FILE"
    
    log_success "IOD V3 host entries removed successfully"
}

# Function to show current entries
show_entries() {
    log_info "Current IOD V3 host entries:"
    echo ""
    
    if entries_exist; then
        # Extract entries between markers
        awk "
            BEGIN { show = 0 }
            /$HOSTS_MARKER/ { 
                if (show == 0) { show = 1; next }
                else { show = 0; next }
            }
            show == 1 { print \"  \" \$0 }
        " "$HOSTS_FILE"
        echo ""
        log_success "IOD V3 entries are currently active"
    else
        log_warning "No IOD V3 entries found in $HOSTS_FILE"
    fi
}

# Function to test host resolution
test_hosts() {
    log_info "Testing host resolution..."
    echo ""
    
    local all_success=true
    
    for entry in "${HOSTS_ENTRIES[@]}"; do
        local hostname=$(echo "$entry" | awk '{print $2}')
        
        if ping -c 1 -W 1 "$hostname" &>/dev/null; then
            log_success "$hostname resolves correctly"
        else
            log_error "$hostname does not resolve"
            all_success=false
        fi
    done
    
    echo ""
    if $all_success; then
        log_success "All IOD V3 hosts resolve correctly"
    else
        log_warning "Some hosts are not resolving. Check your configuration."
    fi
}

# Function to show usage
show_usage() {
    echo "IOD V3 Backend - Host Management Script"
    echo ""
    echo "Usage: sudo $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  add     - Add IOD V3 host entries to $HOSTS_FILE"
    echo "  remove  - Remove IOD V3 host entries from $HOSTS_FILE"
    echo "  show    - Show current IOD V3 host entries"
    echo "  test    - Test if IOD V3 hosts resolve correctly"
    echo "  help    - Show this help message"
    echo ""
    echo "Host entries managed:"
    for entry in "${HOSTS_ENTRIES[@]}"; do
        echo "  $entry"
    done
    echo ""
    echo "Examples:"
    echo "  sudo $0 add     # Add entries"
    echo "  sudo $0 remove  # Remove entries"
    echo "  sudo $0 show    # Show current entries"
    echo "  sudo $0 test    # Test resolution"
}

# Main script logic
case "${1:-help}" in
    "add")
        check_permissions
        add_entries
        ;;
    "remove")
        check_permissions
        remove_entries
        ;;
    "show")
        show_entries
        ;;
    "test")
        test_hosts
        ;;
    "help"|"--help"|"-h")
        show_usage
        ;;
    *)
        log_error "Invalid command: ${1}"
        echo ""
        show_usage
        exit 1
        ;;
esac
