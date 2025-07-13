#!/bin/bash

# Simple Build Test for rAthena Separated Workflow
# This is a minimal test to verify the separated build workflow works

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Test results
PASSED_TESTS=()
FAILED_TESTS=()

# Simple cleanup function
simple_cleanup() {
    print_info "Cleaning up..."
    rm -f .rathena_config Makefile
    rm -f login-server char-server map-server web-server
    # Use a more robust cleanup for build directories
    if [ -d build ]; then
        chmod -R 755 build 2>/dev/null || true
        rm -rf build 2>/dev/null || mv build "build-backup-$$" 2>/dev/null || true
    fi
    sleep 1
}

# Test CMake build
test_cmake_simple() {
    print_info "Testing CMake separated workflow..."
    
    simple_cleanup
    
    # Configure
    if ./configure -t Release >/dev/null 2>&1; then
        print_success "CMake configuration successful"
    else
        print_error "CMake configuration failed"
        FAILED_TESTS+=("cmake-config")
        return 1
    fi
    
    # Build
    if ./build.sh -j 2 >/dev/null 2>&1; then
        print_success "CMake build successful"
    else
        print_error "CMake build failed"
        FAILED_TESTS+=("cmake-build")
        return 1
    fi
    
    # Check executables
    local found_exes=0
    for exe in login-server char-server map-server; do
        if [ -f "$exe" ]; then
            ((found_exes++))
        fi
    done
    
    if [ $found_exes -ge 3 ]; then
        print_success "CMake executables found ($found_exes/3)"
        PASSED_TESTS+=("cmake-workflow")
    else
        print_error "CMake executables missing ($found_exes/3)"
        FAILED_TESTS+=("cmake-executables")
        return 1
    fi
    
    return 0
}

# Test Make build
test_make_simple() {
    print_info "Testing Make separated workflow..."
    
    simple_cleanup
    
    # Configure
    if ./configure -m >/dev/null 2>&1; then
        print_success "Make configuration successful"
    else
        print_error "Make configuration failed"
        FAILED_TESTS+=("make-config")
        return 1
    fi
    
    # Build
    if ./build.sh -j 2 >/dev/null 2>&1; then
        print_success "Make build successful"
    else
        print_error "Make build failed"
        FAILED_TESTS+=("make-build")
        return 1
    fi
    
    # Check executables
    local found_exes=0
    for exe in login-server char-server map-server; do
        if [ -f "$exe" ]; then
            ((found_exes++))
        fi
    done
    
    if [ $found_exes -ge 3 ]; then
        print_success "Make executables found ($found_exes/3)"
        PASSED_TESTS+=("make-workflow")
    else
        print_error "Make executables missing ($found_exes/3)"
        FAILED_TESTS+=("make-executables")
        return 1
    fi
    
    return 0
}

# Show results
show_results() {
    echo ""
    echo "========================================"
    echo "SIMPLE TEST RESULTS"
    echo "========================================"
    
    if [ ${#PASSED_TESTS[@]} -gt 0 ]; then
        print_success "PASSED TESTS (${#PASSED_TESTS[@]}):"
        for test in "${PASSED_TESTS[@]}"; do
            echo "  ✓ $test"
        done
    fi
    
    if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
        echo ""
        print_error "FAILED TESTS (${#FAILED_TESTS[@]}):"
        for test in "${FAILED_TESTS[@]}"; do
            echo "  ✗ $test"
        done
        echo ""
        return 1
    else
        echo ""
        print_success "All simple tests passed!"
        return 0
    fi
}

# Main function
main() {
    echo "rAthena Simple Separated Build Workflow Test"
    echo "============================================"
    echo ""
    
    # Check prerequisites
    if [ ! -f "configure" ] || [ ! -f "build.sh" ]; then
        print_error "Required scripts not found (configure, build.sh)"
        exit 1
    fi
    
    if [ ! -f "CMakeLists.txt" ]; then
        print_error "Must run from rAthena source directory"
        exit 1
    fi
    
    # Run tests
    test_cmake_simple || true
    test_make_simple || true
    
    # Cleanup
    simple_cleanup
    
    # Show results
    show_results
}

# Run main function
main "$@"
