#!/bin/bash

# rAthena Parallel Build Script
# This script provides an easy way to build rAthena with multi-threaded compilation

set -e  # Exit on any error

# Default values
BUILD_TYPE="Release"
BUILD_DIR="build"
JOBS=0  # 0 = auto-detect
CLEAN=false
INSTALL=false
USE_CMAKE=true
VERBOSE=false
CONFIGURE_ARGS=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to detect number of CPU cores
detect_cores() {
    if command -v nproc >/dev/null 2>&1; then
        nproc
    elif [ -f /proc/cpuinfo ]; then
        grep -c ^processor /proc/cpuinfo
    elif command -v sysctl >/dev/null 2>&1; then
        sysctl -n hw.ncpu 2>/dev/null || echo 4
    else
        echo 4
    fi
}

# Function to show usage
show_usage() {
    cat << EOF
rAthena Parallel Build Script

Usage: $0 [OPTIONS] [-- CONFIGURE_OPTIONS]

OPTIONS:
    -j, --jobs NUM          Number of parallel jobs (default: auto-detect)
    -t, --type TYPE         Build type: Debug, Release, RelWithDebInfo (default: Release)
    -d, --dir DIR           Build directory (default: build)
    -c, --clean             Clean build directory before building
    -i, --install           Install after building
    -m, --make              Use traditional make instead of CMake
    -v, --verbose           Verbose output
    -h, --help              Show this help message

CONFIGURE OPTIONS (for traditional make builds):
    All rAthena configure options supported after '--'

    Examples:
    --enable-packetver=VER  Set packet version
    --enable-prere          Enable pre-renewal mode
    --enable-debug          Enable debug mode
    --enable-vip            Enable VIP features
    --with-mysql=PATH       MySQL path

EXAMPLES:
    $0                                          # Auto-detect cores, default config
    $0 -j 8                                     # 8 parallel jobs
    $0 -j 20 -t Debug                          # Debug build with 20 jobs
    $0 -m -- --enable-prere --enable-packetver=20180620  # Pre-renewal build
    $0 -c -i                                    # Clean build and install
    $0 -m -j 16 -- --enable-debug --enable-vip # Make with debug and VIP

NOTE: Configure options only work with traditional make (-m).
      CMake uses its own configuration system.

EOF
}

# Parse command line arguments
configure_mode=false
while [[ $# -gt 0 ]]; do
    if [ "$configure_mode" = true ]; then
        # Everything after -- goes to configure
        CONFIGURE_ARGS="$CONFIGURE_ARGS $1"
        shift
        continue
    fi

    case $1 in
        -j|--jobs)
            JOBS="$2"
            shift 2
            ;;
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -d|--dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN=true
            shift
            ;;
        -i|--install)
            INSTALL=true
            shift
            ;;
        -m|--make)
            USE_CMAKE=false
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
        --)
            configure_mode=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Auto-detect cores if not specified
if [ "$JOBS" -eq 0 ]; then
    JOBS=$(detect_cores)
    print_info "Auto-detected $JOBS CPU cores"
else
    print_info "Using $JOBS parallel jobs"
fi

# Validate build type
case $BUILD_TYPE in
    Debug|Release|RelWithDebInfo|MinSizeRel)
        ;;
    *)
        print_error "Invalid build type: $BUILD_TYPE"
        print_info "Valid types: Debug, Release, RelWithDebInfo, MinSizeRel"
        exit 1
        ;;
esac



print_info "Build configuration:"
print_info "  Build system: $([ "$USE_CMAKE" = true ] && echo "CMake" || echo "Traditional Make")"
print_info "  Build type: $BUILD_TYPE"
print_info "  Build directory: $BUILD_DIR"
print_info "  Parallel jobs: $JOBS"
print_info "  Clean build: $CLEAN"
print_info "  Install: $INSTALL"

# Check if we're in the rAthena source directory
if [ ! -f "CMakeLists.txt" ] || [ ! -f "configure" ]; then
    print_error "This script must be run from the rAthena source directory"
    exit 1
fi

# Clean build directory if requested
if [ "$CLEAN" = true ]; then
    print_info "Cleaning build directory..."
    rm -rf "$BUILD_DIR"
fi

if [ "$USE_CMAKE" = true ]; then
    # CMake build
    print_info "Starting CMake build..."

    # Handle configure arguments with CMake
    if [ -n "$CONFIGURE_ARGS" ]; then
        print_info "Translating configure arguments for CMake build..."
    fi
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Configure
    print_info "Configuring with CMake..."
    CMAKE_ARGS=(
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE"
        -DENABLE_PARALLEL_BUILD=ON
        -DPARALLEL_BUILD_JOBS="$JOBS"
    )

    if [ "$VERBOSE" = true ]; then
        CMAKE_ARGS+=(-DCMAKE_VERBOSE_MAKEFILE=ON)
    fi

    # Translate configure arguments to CMake arguments
    if [ -n "$CONFIGURE_ARGS" ]; then
        # Parse configure arguments directly into CMAKE_ARGS
        for arg in $CONFIGURE_ARGS; do
            case $arg in
                --enable-prere|--enable-prere=yes)
                    CMAKE_ARGS+=(-DENABLE_PRERE=ON)
                    CMAKE_ARGS+=(-DENABLE_RENEWAL=OFF)
                    print_info "  Translated: $arg -> -DENABLE_PRERE=ON -DENABLE_RENEWAL=OFF"
                    ;;
                --enable-renewal|--enable-renewal=yes)
                    CMAKE_ARGS+=(-DENABLE_RENEWAL=ON)
                    CMAKE_ARGS+=(-DENABLE_PRERE=OFF)
                    print_info "  Translated: $arg -> -DENABLE_RENEWAL=ON -DENABLE_PRERE=OFF"
                    ;;
                --enable-packetver=*)
                    local packetver="${arg#*=}"
                    CMAKE_ARGS+=(-DPACKETVER="$packetver")
                    print_info "  Translated: $arg -> -DPACKETVER=$packetver"
                    ;;
                --enable-debug|--enable-debug=yes)
                    CMAKE_ARGS+=(-DENABLE_DEBUG=ON)
                    print_info "  Translated: $arg -> -DENABLE_DEBUG=ON"
                    ;;
                --enable-vip|--enable-vip=yes)
                    CMAKE_ARGS+=(-DENABLE_VIP=ON)
                    print_info "  Translated: $arg -> -DENABLE_VIP=ON"
                    ;;
                --enable-warn|--enable-warn=yes)
                    CMAKE_ARGS+=(-DENABLE_WARN=ON)
                    print_info "  Translated: $arg -> -DENABLE_WARN=ON"
                    ;;
                --enable-epoll|--enable-epoll=yes)
                    CMAKE_ARGS+=(-DENABLE_EPOLL=ON)
                    print_info "  Translated: $arg -> -DENABLE_EPOLL=ON"
                    ;;
                --with-maxconn=*)
                    local maxconn="${arg#*=}"
                    CMAKE_ARGS+=(-DMAXCONN="$maxconn")
                    print_info "  Translated: $arg -> -DMAXCONN=$maxconn"
                    ;;
                --with-mysql=*|--with-pcre=*|--with-zlib=*)
                    print_warning "  Library path option $arg not directly translatable to CMake"
                    ;;
                *)
                    print_warning "  Unknown configure option: $arg (ignored)"
                    ;;
            esac
        done
    fi

    cmake "${CMAKE_ARGS[@]}" ..
    
    # Build
    print_info "Building with $JOBS parallel jobs..."
    BUILD_ARGS=(--build . --config "$BUILD_TYPE" -j "$JOBS")
    
    if [ "$VERBOSE" = true ]; then
        BUILD_ARGS+=(--verbose)
    fi
    
    cmake "${BUILD_ARGS[@]}"
    
    # Install if requested
    if [ "$INSTALL" = true ]; then
        print_info "Installing..."
        cmake --install . --config "$BUILD_TYPE"
    fi
    
else
    # Traditional make build
    print_info "Starting traditional make build..."
    
    # Check if configure has been run or if we have custom arguments
    if [ ! -f "Makefile" ] || [ -n "$CONFIGURE_ARGS" ]; then
        if [ -n "$CONFIGURE_ARGS" ]; then
            print_info "Running configure script with custom options: $CONFIGURE_ARGS"
            ./configure $CONFIGURE_ARGS
        else
            print_info "Running configure script with default options..."
            ./configure
        fi
    fi
    
    # Build with parallel jobs
    print_info "Building with make -j$JOBS..."
    MAKE_ARGS=(-j "$JOBS")
    
    if [ "$VERBOSE" = true ]; then
        MAKE_ARGS+=(V=1)
    fi
    
    make "${MAKE_ARGS[@]}" server
    
    # Install if requested
    if [ "$INSTALL" = true ]; then
        print_info "Installing..."
        make install
    fi
fi

print_success "Build completed successfully!"

if [ "$USE_CMAKE" = true ]; then
    print_info "Executables are in: $BUILD_DIR/"
else
    print_info "Executables are in the source directory"
fi

print_info ""
print_info "To use parallel builds in the future:"
if [ "$USE_CMAKE" = true ]; then
    print_info "  cmake --build $BUILD_DIR -j$JOBS"
else
    print_info "  make -j$JOBS server"
fi
