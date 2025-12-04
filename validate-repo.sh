#!/bin/bash
# Repository Validation Script
# Ensures all configs, scripts, and documentation are present and valid

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

print_msg() { echo -e "${1}${*:2}${NC}"; }
error() { print_msg "$RED" "✗ $1"; ((ERRORS++)); }
warning() { print_msg "$YELLOW" "⚠ $1"; ((WARNINGS++)); }
success() { print_msg "$GREEN" "✓ $1"; }
info() { print_msg "$BLUE" "→ $1"; }

echo "========================================="
echo "  Repository Validation"
echo "========================================="
echo ""

# Get script directory
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

## 1. Check Directory Structure
info "Checking directory structure..."

required_dirs=(
    "audio"
    "audio/pipewire"
    "audio/wireplumber"
    "performance"
    "security"
    "kde-plasma"
    "cron-systemd/borg-scripts"
    "restore"
)

for dir in "${required_dirs[@]}"; do
    if [[ -d "$dir" ]]; then
        success "Directory exists: $dir"
    else
        error "Missing directory: $dir"
    fi
done

echo ""

## 2. Check Required Config Files
info "Checking configuration files..."

required_configs=(
    "audio/pipewire/99-lowlatency.conf"
    "audio/wireplumber/90-alsa-lowlatency.lua"
    "audio/asoundrc"
    "audio/rtirq.conf"
    "performance/tlp.conf"
    "performance/thinkfan.yaml"
    "performance/60-ioschedulers.rules"
    "performance/99-sysctl-performance.conf"
    "security/sshd-hardening.conf"
    "kde-plasma/fix-app-icons.sh"
    "kde-plasma/default.conf"
)

for config in "${required_configs[@]}"; do
    if [[ -f "$config" ]]; then
        success "Config exists: $config"
    else
        error "Missing config: $config"
    fi
done

echo ""

## 3. Check Script Files
info "Checking script files..."

required_scripts=(
    "restore/restore-system.sh"
    "cron-systemd/borg-scripts/backup_t14s_home"
    "cron-systemd/borg-scripts/backup_t14s_sys"
    "cron-systemd/borg-scripts/backup_full_sys"
    "cron-systemd/borg-scripts/backup-wrapper.sh"
    "kde-plasma/restore-plasma-settings.sh"
    "kde-plasma/backup-plasma-settings.sh"
)

for script in "${required_scripts[@]}"; do
    if [[ -f "$script" ]]; then
        if [[ -x "$script" ]]; then
            success "Script exists and executable: $script"
        else
            warning "Script exists but not executable: $script"
        fi
    else
        error "Missing script: $script"
    fi
done

echo ""

## 4. Syntax Validation
info "Validating bash syntax..."

for script in "${required_scripts[@]}" "kde-plasma/fix-app-icons.sh"; do
    if [[ -f "$script" ]]; then
        if bash -n "$script" 2>/dev/null; then
            success "Syntax valid: $script"
        else
            error "Syntax error in: $script"
            bash -n "$script" 2>&1 | head -5
        fi
    fi
done

echo ""

## 5. Check Documentation
info "Checking documentation..."

required_docs=(
    "README.md"
    "audio/README.md"
    "kde-plasma/README.md"
)

for doc in "${required_docs[@]}"; do
    if [[ -f "$doc" ]]; then
        if [[ -s "$doc" ]]; then
            success "Documentation exists: $doc"
        else
            warning "Documentation empty: $doc"
        fi
    else
        warning "Missing documentation: $doc"
    fi
done

echo ""

## 6. Check for Sensitive Data
info "Checking for sensitive data..."

sensitive_patterns=(
    "BORG_PASSPHRASE=.*['\"].*['\"]"
    "password.*=.*['\"]"
    "ssh.*private.*key"
)

found_sensitive=false
for pattern in "${sensitive_patterns[@]}"; do
    if grep -r -i -E "$pattern" --exclude-dir=.git --exclude="*.example" . 2>/dev/null | grep -v "validate-repo.sh" | grep -q .; then
        warning "Found potential sensitive data matching: $pattern"
        found_sensitive=true
    fi
done

if ! $found_sensitive; then
    success "No obvious sensitive data found"
fi

echo ""

## 7. Check .gitignore
info "Checking .gitignore..."

if [[ -f ".gitignore" ]]; then
    if grep -q "\.log" .gitignore && grep -q "credentials" .gitignore; then
        success ".gitignore exists and covers logs/credentials"
    else
        warning ".gitignore exists but may be incomplete"
    fi
else
    error "Missing .gitignore file"
fi

echo ""

## 8. Verify No Duplicate Files
info "Checking for duplicate configs..."

# Check that backup-wrapper.sh only exists in one place
wrapper_count=$(find . -name "backup-wrapper.sh" -type f | wc -l)
if [[ $wrapper_count -eq 1 ]]; then
    success "No duplicate backup-wrapper.sh"
elif [[ $wrapper_count -gt 1 ]]; then
    error "Found $wrapper_count instances of backup-wrapper.sh"
    find . -name "backup-wrapper.sh" -type f
fi

echo ""

## 9. Check Script Size
info "Checking script maintainability..."

restore_script="restore/restore-system.sh"
if [[ -f "$restore_script" ]]; then
    lines=$(wc -l < "$restore_script")
    if [[ $lines -lt 1500 ]]; then
        success "Main script size reasonable: $lines lines"
    elif [[ $lines -lt 2000 ]]; then
        warning "Main script getting large: $lines lines (consider modularizing)"
    else
        error "Main script too large: $lines lines (needs modularization)"
    fi
fi

echo ""

## 10. Optional: shellcheck
info "Checking for shellcheck..."

if command -v shellcheck &>/dev/null; then
    success "shellcheck available - running analysis..."

    for script in "${required_scripts[@]}" "kde-plasma/fix-app-icons.sh"; do
        if [[ -f "$script" ]]; then
            if shellcheck "$script" 2>/dev/null; then
                success "shellcheck passed: $script"
            else
                warning "shellcheck warnings in: $script"
            fi
        fi
    done
else
    warning "shellcheck not installed (recommended: sudo pacman -S shellcheck)"
fi

echo ""
echo "========================================="
echo "  Validation Summary"
echo "========================================="

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    print_msg "$GREEN" "✓ PERFECT! Repository passed all checks (10/10)"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    print_msg "$YELLOW" "⚠ Repository is good with $WARNINGS warnings (9/10)"
    exit 0
else
    print_msg "$RED" "✗ Repository has $ERRORS errors and $WARNINGS warnings"
    echo ""
    echo "Fix errors above to reach production quality."
    exit 1
fi
