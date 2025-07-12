# rAthena Configure Options Integration Guide

This guide explains how to use rAthena's traditional configure options with the parallel build system.

## Table of Contents

- [Overview](#overview)
- [Build System Differences](#build-system-differences)
- [Traditional Make with Configure Options](#traditional-make-with-configure-options)
- [CMake Limitations](#cmake-limitations)
- [Common Configure Options](#common-configure-options)
- [Usage Examples](#usage-examples)
- [Workflow Recommendations](#workflow-recommendations)

## Overview

rAthena supports two build systems:

1. **Traditional autotools/Make** - Supports all configure options
2. **CMake** - Uses its own configuration system (limited configure option support)

The parallel build system integrates with both, but configure options work differently in each.

## Build System Differences

### Traditional Make (Recommended for Configure Options)

✅ **Full configure option support**  
✅ **All rAthena features configurable**  
✅ **Parallel compilation with `make -j<N>`**  
✅ **Integrates seamlessly with existing workflows**

### CMake

✅ **Modern build system**  
✅ **Excellent parallel build support**  
✅ **Cross-platform compatibility**  
❌ **Limited configure option support**  
❌ **Requires manual configuration for rAthena-specific features**

## Traditional Make with Configure Options

### Basic Workflow

```bash
# Method 1: Enhanced script (recommended)
./configure-parallel.sh -j 8 -- --enable-prere --enable-packetver=20180620

# Method 2: Build script with configure options
./build-parallel.sh -m -j 8 -- --enable-debug --enable-vip

# Method 3: Manual approach
./configure --enable-renewal --with-mysql=/usr/local/mysql
make -j 8 server
```

### Configure Arguments Syntax

Use `--` to separate parallel build options from configure options:

```bash
script [PARALLEL_OPTIONS] -- [CONFIGURE_OPTIONS]
```

## CMake Limitations

CMake builds **do not support** traditional configure options because:

1. CMake uses its own configuration system
2. rAthena's CMake configuration doesn't translate all autotools options
3. Feature flags would need to be implemented separately for CMake

### CMake Workaround

For features requiring configure options, use traditional make:

```bash
# Instead of this (won't work):
./build-parallel.sh -j 8 -- --enable-prere

# Use this:
./build-parallel.sh -m -j 8 -- --enable-prere
```

## Common Configure Options

### Game Mode Configuration

| Option | Description | Example |
|--------|-------------|---------|
| `--enable-renewal` | Enable renewal mode (default) | `--enable-renewal` |
| `--enable-prere` | Enable pre-renewal mode | `--enable-prere` |

### Packet Version

| Option | Description | Example |
|--------|-------------|---------|
| `--enable-packetver=VER` | Set client packet version | `--enable-packetver=20180620` |

### Debug and Development

| Option | Description | Example |
|--------|-------------|---------|
| `--enable-debug` | Enable debug mode | `--enable-debug` |
| `--enable-warn` | Enable compiler warnings | `--enable-warn` |
| `--enable-vip` | Enable VIP features | `--enable-vip` |

### Database Configuration

| Option | Description | Example |
|--------|-------------|---------|
| `--with-mysql=PATH` | MySQL installation path | `--with-mysql=/usr/local/mysql` |
| `--with-MYSQL_CFLAGS=FLAGS` | Custom MySQL compile flags | `--with-MYSQL_CFLAGS="-I/custom/path"` |
| `--with-MYSQL_LIBS=LIBS` | Custom MySQL libraries | `--with-MYSQL_LIBS="-L/custom/path -lmysqlclient"` |

### Library Paths

| Option | Description | Example |
|--------|-------------|---------|
| `--with-pcre=PATH` | PCRE library path | `--with-pcre=/usr/local` |
| `--with-zlib=PATH` | Zlib library path | `--with-zlib=/usr/local` |

### Performance Options

| Option | Description | Example |
|--------|-------------|---------|
| `--with-maxconn=NUM` | Maximum connections | `--with-maxconn=16384` |
| `--enable-epoll` | Use epoll on Linux | `--enable-epoll` |
| `--enable-rdtsc` | Use RDTSC timing | `--enable-rdtsc` |

## Usage Examples

### Pre-Renewal Server

```bash
# Pre-renewal with specific packet version
./configure-parallel.sh -j 16 -- --enable-prere --enable-packetver=20180620

# Alternative using build script
./build-parallel.sh -m -j 16 -- --enable-prere --enable-packetver=20180620
```

### Development Build

```bash
# Debug build with warnings and VIP features
./configure-parallel.sh -j 8 -- --enable-debug --enable-warn --enable-vip

# Clean debug build
./build-parallel.sh -m -c -j 8 -- --enable-debug --enable-warn
```

### Custom Database Setup

```bash
# Custom MySQL installation
./configure-parallel.sh -j 12 -- --with-mysql=/opt/mysql --enable-renewal

# Custom library paths
./build-parallel.sh -m -j 8 -- --with-mysql=/usr/local/mysql --with-pcre=/usr/local --with-zlib=/usr/local
```

### High-Performance Server

```bash
# Maximum connections with epoll
./configure-parallel.sh -j 20 -- --with-maxconn=32768 --enable-epoll --enable-renewal

# Release build with optimizations
./build-parallel.sh -m -j 16 -- --enable-lto --with-maxconn=16384
```

## Workflow Recommendations

### For New Projects

1. **Determine your requirements:**
   - Game mode (renewal vs pre-renewal)
   - Packet version compatibility
   - Debug vs release build

2. **Choose build system:**
   - **Traditional Make**: If you need configure options
   - **CMake**: If you want modern build system and don't need special options

3. **Use enhanced script:**
   ```bash
   ./configure-parallel.sh -j $(nproc) -- [your-configure-options]
   ```

### For Existing Projects

1. **Check current configuration:**
   ```bash
   # See what configure options were used
   head -20 config.log
   ```

2. **Migrate to parallel builds:**
   ```bash
   # Keep same configure options, add parallel compilation
   ./build-parallel.sh -m -j 8 -- [existing-configure-options]
   ```

### For CI/CD Pipelines

```bash
# Automated build with specific configuration
./configure-parallel.sh -j $(nproc) -- --enable-renewal --enable-packetver=20200401 --enable-warn
```

## Integration Summary

| Scenario | Recommended Approach | Command Example |
|----------|---------------------|-----------------|
| **Default build** | CMake or Make | `./build-parallel.sh -j 8` |
| **Pre-renewal** | Traditional Make | `./build-parallel.sh -m -j 8 -- --enable-prere` |
| **Debug build** | Traditional Make | `./build-parallel.sh -m -j 8 -- --enable-debug` |
| **Custom packet version** | Traditional Make | `./build-parallel.sh -m -j 8 -- --enable-packetver=20180620` |
| **Custom MySQL** | Traditional Make | `./build-parallel.sh -m -j 8 -- --with-mysql=/path` |
| **Modern development** | CMake | `./build-parallel.sh -j 8` |

## Troubleshooting

### Configure Options Not Working

**Problem:** Configure options seem to be ignored  
**Solution:** Make sure you're using traditional make (`-m` flag) and proper `--` separator

```bash
# Wrong (configure options ignored with CMake)
./build-parallel.sh -j 8 -- --enable-prere

# Correct
./build-parallel.sh -m -j 8 -- --enable-prere
```

### Build Fails After Configure

**Problem:** Build fails after running configure with custom options  
**Solution:** Clean build and try again

```bash
./build-parallel.sh -m -c -j 8 -- [your-options]
```

### Performance Issues

**Problem:** Parallel build not faster with configure options  
**Solution:** Traditional make parallel builds work the same as CMake

```bash
# Both should give similar performance
make -j 8 server                    # Traditional
./build-parallel.sh -m -j 8         # Enhanced
```

---

For more information:
- [PARALLEL_BUILD.md](PARALLEL_BUILD.md) - General parallel build guide
- [TROUBLESHOOTING_PARALLEL_BUILD.md](TROUBLESHOOTING_PARALLEL_BUILD.md) - Troubleshooting guide
