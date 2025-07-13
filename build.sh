#!/bin/bash

# rAthena Enhanced Build Script
# This script handles the build step of the separated workflow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

# Default values
PARALLEL_JOBS=""
CLEAN_BUILD=false
INSTALL_AFTER=false
VERBOSE=false
CONFIG_FILE=".rathena_config"

# Function to show usage
show_usage() {
    echo "rAthena Enhanced Build Script"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -j NUM     Number of parallel jobs (default: auto-detect)"
    echo "  -c         Clean build (remove previous build files)"
    echo "  -i         Install after building"
    echo "  -v         Verbose output"
    echo "  -h         Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build with auto-detected cores"
    echo "  $0 -j 8              # Build with 8 parallel jobs"
    echo "  $0 -c -j 4           # Clean build with 4 jobs"
    echo "  $0 -v -i             # Verbose build with install"
}

# Function to parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -j|--jobs)
                PARALLEL_JOBS="$2"
                shift 2
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            -i|--install)
                INSTALL_AFTER=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Function to load configuration
load_configuration() {
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        print_error "Please run './configure' first"
        exit 1
    fi
    
    print_info "Loading configuration from $CONFIG_FILE"
    source "$CONFIG_FILE"
    
    # Auto-detect parallel jobs if not specified
    if [ -z "$PARALLEL_JOBS" ]; then
        PARALLEL_JOBS=$(nproc 2>/dev/null || echo "4")
    fi
    
    print_info "Using $PARALLEL_JOBS parallel jobs"
}

# Function to show build configuration
show_build_config() {
    print_info "Build configuration:"
    print_info "  Build system: $([ "$USE_CMAKE" = true ] && echo "CMake" || echo "Traditional Make")"
    print_info "  Build type: $BUILD_TYPE"
    print_info "  Build directory: $BUILD_DIR"
    print_info "  Parallel jobs: $PARALLEL_JOBS"
    print_info "  Clean build: $CLEAN_BUILD"
    print_info "  Install: $INSTALL_AFTER"
    echo ""
}

# Function to build with CMake
build_cmake() {
    print_info "Starting CMake build..."
    
    # Clean build if requested
    if [ "$CLEAN_BUILD" = true ]; then
        print_info "Cleaning previous build..."
        rm -rf "$BUILD_DIR"
    fi
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    
    # Configure CMake if not already configured
    if [ ! -f "$BUILD_DIR/CMakeCache.txt" ]; then
        print_info "CMake not configured yet. Running initial configuration..."
        cd "$BUILD_DIR"
        cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
              -DENABLE_PARALLEL_BUILD=ON \
              -DPARALLEL_BUILD_JOBS="$PARALLEL_JOBS" \
              .. || {
            print_error "CMake configuration failed"
            exit 1
        }
        cd ..
    fi
    
    # Build
    print_info "Building with $PARALLEL_JOBS parallel jobs..."
    if [ "$VERBOSE" = true ]; then
        cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" -j "$PARALLEL_JOBS" --verbose
    else
        cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" -j "$PARALLEL_JOBS"
    fi
    
    # Install if requested
    if [ "$INSTALL_AFTER" = true ]; then
        print_info "Installing..."
        cmake --build "$BUILD_DIR" --target install
    fi
    
    print_success "Build completed successfully!"
    print_info "Executables are in: $BUILD_DIR/"
    print_info ""
    print_info "To use parallel builds in the future:"
    print_info "  cmake --build $BUILD_DIR -j$PARALLEL_JOBS"
}

# Function to build with traditional make
build_make() {
    print_info "Starting traditional make build..."
    
    # Clean build if requested
    if [ "$CLEAN_BUILD" = true ]; then
        print_info "Cleaning previous build..."
        if [ -f Makefile ]; then
            make clean || true
        fi
        rm -f login-server char-server map-server web-server
    fi
    
    # Check if Makefile exists
    if [ ! -f Makefile ]; then
        print_error "Makefile not found. Please run './configure -m' first"
        exit 1
    fi
    
    # Build
    print_info "Building with make -j$PARALLEL_JOBS..."
    if [ "$VERBOSE" = true ]; then
        make -j "$PARALLEL_JOBS" server V=1
    else
        make -j "$PARALLEL_JOBS" server
    fi
    
    # Install if requested
    if [ "$INSTALL_AFTER" = true ]; then
        print_info "Installing..."
        make install
    fi
    
    print_success "Build completed successfully!"
    print_info "Executables are in the source directory"
    print_info ""
    print_info "To use parallel builds in the future:"
    print_info "  make -j$PARALLEL_JOBS server"
}

# Main function
main() {
    echo "rAthena Enhanced Build"
    echo "====================="
    echo ""
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Load configuration
    load_configuration
    
    # Show build configuration
    show_build_config
    
    # Build based on configuration
    if [ "$USE_CMAKE" = true ]; then
        build_cmake
    else
        build_make
    fi
}

# Run main function
main "$@"
